import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/geo/geo_exception.dart';
import '../../../../core/geo/geo_models.dart';
import '../../data/pin_label_resolver.dart';
import '../../data/repositories/places_repository.dart';
import 'map_pick_state.dart';

/// Drives the home map's pick mode: the customer drags the map under a
/// center pin (or searches for a place), the address under the pin is looked
/// up, and confirming hands back the chosen [PickedLocationModel].
///
/// The map widget reports where its camera is through [onCameraMove] and
/// [onCameraIdle] at all times, so entering the mode knows the pin position.
class MapPickCubit extends Cubit<MapPickState> {
  /// How close the pin must be to a known place (a suggestion, or the point
  /// being edited) to reuse its address when the lookup fails — a few meters,
  /// since the camera may settle a hair off.
  static const _anchorTolerance = 0.0001;

  /// The pause in typing after which suggestions are asked for.
  static const suggestDebounce = Duration(milliseconds: 250);

  final PlacesRepository _places;
  final CurrentLocationService _location;

  Timer? _suggestTimer;

  /// What is in the search box, for the Search button.
  String _typedText = '';

  /// The text suggestions were last asked for (or are about to be): the same
  /// text is not asked twice, and an answer for any other is out of date.
  String _suggestQuery = '';

  double _centerLat = AppConstants.defaultMapLat;
  double _centerLng = AppConstants.defaultMapLng;

  /// Where the customer actually is — what "nearest first" is measured from.
  /// Null until a fix is had; the search then uses the pin's position.
  ({double lat, double lng})? _userPosition;

  /// A place whose address is already known: it stands in if the reverse
  /// lookup for that same spot fails.
  ({double lat, double lng, String address})? _anchor;

  /// The query last submitted: an answer for any other is out of date.
  String _query = '';

  /// The point the server resolved a search to, until the pin is confirmed:
  /// the confirmed pin is compared with it (feedback, and the order's
  /// `alias_id`).
  ({int aliasId, double lat, double lng})? _resolved;

  /// The point being edited came with an `alias_id`; kept while the pin stays
  /// within 150 m of it.
  ({int aliasId, double lat, double lng})? _initialAlias;

  MapPickCubit(this._places, this._location) : super(const MapPickState());

  /// Starts picking [target]. [initial] is the point already chosen for it:
  /// the map moves there. Without one, the pin starts where the map is.
  /// [autofocusSearch] says the customer came in to type a place (the keyboard
  /// is open on the field), so the pin is not named until it is moved.
  void enter(
    PickTarget target, {
    PickedLocationModel? initial,
    bool autofocusSearch = false,
  }) {
    if (isClosed) return;
    _clearSuggestions();
    _query = '';
    _typedText = '';
    _resolved = null;
    _initialAlias = initial?.aliasId == null
        ? null
        : (
            aliasId: initial!.aliasId!,
            lat: initial.latitude,
            lng: initial.longitude,
          );
    _anchor = initial?.address == null
        ? null
        : (
            lat: initial!.latitude,
            lng: initial.longitude,
            address: initial.address!,
          );
    // Coming in through the search box, the customer is about to type a place:
    // naming the map's center now would be a paid lookup for nothing. It is
    // named if they move the map or confirm.
    final deferNaming = initial == null && autofocusSearch;
    emit(
      MapPickState(
        target: target,
        addressDeferred: deferNaming,
        address: initial?.address,
        moveTarget: state.moveTarget,
        moveCount: state.moveCount,
      ),
    );
    unawaited(_loadUserPosition());
    if (initial != null) {
      _centerLat = initial.latitude;
      _centerLng = initial.longitude;
      _moveTo(initial.latitude, initial.longitude, 16);
    } else if (!deferNaming) {
      _resolveCenter(reason: 'pick mode opened');
    }
  }

  /// Leaves the mode without choosing anything.
  void cancel() {
    if (isClosed) return;
    _places.cancelSearch();
    _clearSuggestions();
    _query = '';
    _typedText = '';
    _anchor = null;
    _resolved = null;
    _initialAlias = null;
    emit(
      MapPickState(moveTarget: state.moveTarget, moveCount: state.moveCount),
    );
  }

  /// Leaves the mode with the point under the pin, or returns null (and stays)
  /// while there is no resolved address to confirm. A pin whose naming was
  /// put off is named now; if that finds nothing the mode stays, with the
  /// retry button.
  Future<PickedLocationModel?> confirm({String? details}) async {
    if (isClosed || !state.canConfirm) return null;
    if (state.address == null) await _resolveCenter(reason: 'confirm');
    final address = state.address;
    if (isClosed || !state.canConfirm || address == null) return null;
    final trimmed = details?.trim();
    final picked = PickedLocationModel(
      latitude: _centerLat,
      longitude: _centerLng,
      address: address,
      addressDetails: trimmed == null || trimmed.isEmpty ? null : trimmed,
      aliasId: _confirmedAliasId(),
    );
    cancel();
    return picked;
  }

  /// The camera starts moving (a drag, or the map flying to a place).
  void onCameraMoveStarted() {
    if (!isClosed && state.isPicking && !state.isDragging) {
      emit(state.copyWith(isDragging: true, isTyping: false));
    }
  }

  void onCameraMove(double lat, double lng) {
    _centerLat = lat;
    _centerLng = lng;
    // The old address belongs to the old pin position; drop it right away so
    // it can't be confirmed for the new one.
    if (!isClosed && state.isPicking && state.address != null) {
      emit(state.copyWith(clearAddress: true));
    }
  }

  void onCameraIdle(double lat, double lng) {
    _centerLat = lat;
    _centerLng = lng;
    if (isClosed || !state.isPicking) return;
    final wasDragging = state.isDragging;
    if (wasDragging) emit(state.copyWith(isDragging: false));
    // The pin was not moved since the customer came in through the search
    // box (the map only settled, or resized for the keyboard): nothing to
    // name yet.
    if (state.addressDeferred && !wasDragging) return;
    _resolveCenter(reason: 'camera idle');
  }

  /// The search box text changed. Nothing is searched while typing: only the
  /// keyboard's search key (or the icon) does, through [submitSearch]. What is
  /// typed does bring up to 5 of our own places under the field, after a short
  /// pause ([suggestDebounce]) and from 2 characters. Clearing the box drops
  /// a search still on its way.
  void queryChanged(String text) {
    if (isClosed) return;
    _typedText = text;
    if (text.trim().isEmpty) {
      _query = '';
      _places.cancelSearch();
      _clearSuggestions();
      emit(
        state.copyWith(
          isSearching: false,
          isTyping: false,
          clearSearchError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isTyping: true,
          clearSearchError: state.searchError != null,
        ),
      );
      _scheduleSuggest(text);
    }
  }

  /// The Search button: searches what is in the box.
  Future<void> searchTyped() => submitSearch(_typedText);

  void _scheduleSuggest(String text) {
    final typed = PlacesRepository.normalizeQuery(text);
    _suggestTimer?.cancel();
    if (!PlacesRepository.isSearchable(typed)) {
      _clearSuggestions();
      return;
    }
    if (typed == _suggestQuery) return;
    // The list under the field is for the old text; the new one's answer
    // replaces it.
    _places.cancelSuggest();
    _suggestQuery = typed;
    _suggestTimer = Timer(suggestDebounce, () => _loadSuggestions(typed));
  }

  Future<void> _loadSuggestions(String typed) async {
    try {
      final found = await _places.suggest(typed);
      if (isClosed || typed != _suggestQuery) return;
      emit(state.copyWith(suggestions: found));
    } on GeoException {
      // Replaced by a newer call, which reports for itself.
    }
  }

  /// Hides the list and forgets what it was asked for.
  void _clearSuggestions() {
    _suggestTimer?.cancel();
    _places.cancelSuggest();
    _suggestQuery = '';
    if (!isClosed && state.suggestions.isNotEmpty) {
      emit(state.copyWith(suggestions: const []));
    }
  }

  /// The customer tapped [suggestion]. With coordinates the map goes there at
  /// once and the server confirms in the background (free for these places);
  /// without (the saved point is old) the pin waits for the server's answer.
  /// Either way its text stays the title of the chosen place.
  Future<void> selectSuggestion(GeoSuggestionModel suggestion) async {
    if (isClosed) return;
    _clearSuggestions();
    _query = '';
    final lat = suggestion.lat;
    final lng = suggestion.lng;
    if (lat == null || lng == null) {
      await _resolve(
        suggestion.text,
        aliasId: suggestion.aliasId,
        title: suggestion.text,
      );
      return;
    }
    _applyFound(
      PlaceFound(
        label: suggestion.text,
        latitude: lat,
        longitude: lng,
        aliasId: suggestion.aliasId,
      ),
    );
    await _confirmInBackground(suggestion);
  }

  /// Asks the server to resolve the tapped place. Its point replaces ours for
  /// the feedback; the map is not moved again.
  Future<void> _confirmInBackground(GeoSuggestionModel suggestion) async {
    try {
      final outcome = await _places.submit(
        suggestion.text,
        aliasId: suggestion.aliasId,
      );
      final current = _resolved;
      if (isClosed ||
          current == null ||
          current.aliasId != suggestion.aliasId) {
        return;
      }
      if (outcome is PlaceFound) {
        _resolved = (
          aliasId: outcome.aliasId,
          lat: outcome.latitude,
          lng: outcome.longitude,
        );
      }
    } on GeoException {
      // Replaced by a newer search, which reports for itself.
    }
  }

  /// The customer submitted [query] (the keyboard's search key, or the search
  /// icon): the server turns it into a point.
  Future<void> submitSearch(String query) async {
    if (isClosed) return;
    _clearSuggestions();
    if (!PlacesRepository.isSearchable(query)) {
      _query = '';
      _places.cancelSearch();
      emit(
        state.copyWith(
          isSearching: false,
          searchError: AppStrings.current.searchMinChars,
        ),
      );
      return;
    }
    // The same query again changes nothing while it is on its way.
    final normalized = PlacesRepository.normalizeQuery(query);
    if (normalized == _query && state.isSearching) return;
    _query = normalized;
    await _resolve(query);
  }

  /// The answer to "did you mean …?": yes continues with the suggested place,
  /// no with Google's own answer.
  Future<void> answerDidYouMean({required bool yes}) async {
    final prompt = state.didYouMean;
    if (isClosed || prompt == null) return;
    emit(state.copyWith(clearDidYouMean: true));
    await _resolve(
      prompt.query,
      aliasId: yes ? prompt.aliasId : null,
      forceGoogle: !yes,
    );
  }

  /// The "did you mean …?" was closed without an answer.
  void dismissDidYouMean() {
    if (!isClosed) {
      emit(state.copyWith(isSearching: false, clearDidYouMean: true));
    }
  }

  void clearSearch() => queryChanged('');

  /// Hides the search message, e.g. when the customer taps the map.
  void dismissSuggestions() {
    if (isClosed) return;
    _clearSuggestions();
    if (state.searchError == null) return;
    emit(state.copyWith(clearSearchError: true));
  }

  /// Puts the pin on one of the customer's saved places. Without a stored
  /// address, the address under the pin is looked up as for any dragged pin.
  void selectSaved(PickedLocationModel place) {
    if (isClosed) return;
    _places.cancelSearch();
    _clearSuggestions();
    _resolved = null;
    final address = place.address;
    _anchor = address == null
        ? null
        : (lat: place.latitude, lng: place.longitude, address: address);
    _centerLat = place.latitude;
    _centerLng = place.longitude;
    emit(
      state.copyWith(
        address: address,
        clearAddress: address == null,
        isResolving: false,
        addressDeferred: false,
        isSearching: false,
        isTyping: false,
        clearSearchError: true,
      ),
    );
    _moveTo(place.latitude, place.longitude, 17);
    // The map may already be there, in which case it never goes idle again.
    if (address == null) _resolveCenter(reason: 'saved place without address');
  }

  /// Retry button after a failed address lookup.
  void retryResolve() {
    if (!isClosed && state.isPicking) _resolveCenter(reason: 'retry');
  }

  void _moveTo(double lat, double lng, double zoom) {
    emit(
      state.copyWith(
        moveTarget: PickedLocationModel(latitude: lat, longitude: lng),
        moveZoom: zoom,
        moveCount: state.moveCount + 1,
      ),
    );
  }

  Future<void> _loadUserPosition() async {
    final position = await _location.getPositionIfAllowed();
    if (position != null) {
      _userPosition ??= (lat: position.latitude, lng: position.longitude);
    }
  }

  Future<void> _resolve(
    String query, {
    int? aliasId,
    bool forceGoogle = false,
    String? title,
  }) async {
    emit(state.copyWith(isSearching: true, clearSearchError: true));
    try {
      final outcome = await _places.submit(
        query,
        aliasId: aliasId,
        forceGoogle: forceGoogle,
      );
      if (isClosed) return;
      _applyOutcome(outcome, query, title: title);
    } on GeoException {
      // Replaced by a newer search, which reports for itself.
    }
  }

  void _applyOutcome(PlaceOutcome outcome, String query, {String? title}) {
    switch (outcome) {
      case PlaceFound():
        // A tapped suggestion keeps its own text as the title.
        _applyFound(title == null ? outcome : outcome.withLabel(title));
      case PlaceDidYouMean():
        emit(
          state.copyWith(
            isSearching: false,
            didYouMean: DidYouMeanPrompt(
              query: query,
              aliasId: outcome.aliasId,
              text: outcome.text,
            ),
          ),
        );
      case PlaceNotFound():
        emit(
          state.copyWith(
            isSearching: false,
            searchError: AppStrings.current.placesNotFoundMovePin,
          ),
        );
    }
  }

  void _applyFound(PlaceFound found) {
    _resolved = (
      aliasId: found.aliasId,
      lat: found.latitude,
      lng: found.longitude,
    );
    _anchor = (lat: found.latitude, lng: found.longitude, address: found.label);
    _centerLat = found.latitude;
    _centerLng = found.longitude;
    emit(
      state.copyWith(
        address: found.label,
        isResolving: false,
        addressDeferred: false,
        isSearching: false,
        isTyping: false,
        clearSearchError: true,
        correctedTo: found.correctedTo,
      ),
    );
    _moveTo(found.latitude, found.longitude, 17);
    if (found.correctedTo != null) emit(state.copyWith(clearCorrectedTo: true));
  }

  /// What the order carries as the point's `alias_id`: the resolved place's
  /// when the confirmed pin stayed on it (the server also hears whether it
  /// did), otherwise that of the point being edited if the pin is still there.
  int? _confirmedAliasId() {
    final resolved = _resolved;
    _resolved = null;
    if (resolved != null) {
      final stayed = _places.reportConfirmed(
        aliasId: resolved.aliasId,
        resolvedLatitude: resolved.lat,
        resolvedLongitude: resolved.lng,
        pinLatitude: _centerLat,
        pinLongitude: _centerLng,
      );
      return stayed ? resolved.aliasId : null;
    }
    final initial = _initialAlias;
    if (initial == null) return null;
    final meters = PinLabelResolver.distanceMeters(
      initial.lat,
      initial.lng,
      _centerLat,
      _centerLng,
    );
    return meters <= PlacesRepository.acceptedMeters ? initial.aliasId : null;
  }

  Future<void> _resolveCenter({required String reason}) async {
    final lat = _centerLat;
    final lng = _centerLng;
    // The pin is still on the place the customer chose (a search result or a
    // saved place): its own name is the right one, and no lookup could
    // improve on it — it would name the street under it instead.
    final anchored = _anchorAddressAt(lat, lng);
    if (anchored != null) {
      emit(
        state.copyWith(
          address: anchored,
          isResolving: false,
          addressDeferred: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        clearAddress: true,
        isResolving: true,
        addressDeferred: false,
      ),
    );
    final address = await _places.addressFor(lat, lng, reason: reason);
    // The pin moved on (or the mode ended) while this ran; the newer lookup
    // owns the state now.
    if (isClosed ||
        !state.isPicking ||
        _centerLat != lat ||
        _centerLng != lng) {
      return;
    }
    emit(state.copyWith(address: address, isResolving: false));
  }

  String? _anchorAddressAt(double lat, double lng) {
    final anchor = _anchor;
    if (anchor == null) return null;
    final isSamePlace =
        (anchor.lat - lat).abs() < _anchorTolerance &&
        (anchor.lng - lng).abs() < _anchorTolerance;
    return isSamePlace ? anchor.address : null;
  }

  @override
  Future<void> close() {
    _suggestTimer?.cancel();
    _places.cancelSearch();
    return super.close();
  }
}
