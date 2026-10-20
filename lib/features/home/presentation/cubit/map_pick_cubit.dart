import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../data/models/place_suggestion_model.dart';
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

  final PlacesRepository _places;
  final CurrentLocationService _location;

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

  /// What the search box holds right now: the list of recent places that
  /// loads for it is out of date once the box changes.
  String _typed = '';

  MapPickCubit(this._places, this._location) : super(const MapPickState());

  /// Starts picking [target]. [initial] is the point already chosen for it:
  /// the map moves there. Without one, the pin starts where the map is.
  /// [autofocusSearch] opens the search box with the keyboard.
  void enter(
    PickTarget target, {
    PickedLocationModel? initial,
    bool autofocusSearch = false,
  }) {
    if (isClosed) return;
    _query = '';
    _typed = '';
    _anchor = initial?.address == null
        ? null
        : (lat: initial!.latitude, lng: initial.longitude, address: initial.address!);
    // Coming in through the search box, the customer is about to type a place:
    // naming the map's center now would be a paid lookup for nothing. It is
    // named if they move the map or confirm.
    final deferNaming = initial == null && autofocusSearch;
    emit(MapPickState(
      target: target,
      autofocusSearch: autofocusSearch,
      addressDeferred: deferNaming,
      address: initial?.address,
      moveTarget: state.moveTarget,
      moveCount: state.moveCount,
    ));
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
    _query = '';
    _typed = '';
    _anchor = null;
    emit(MapPickState(moveTarget: state.moveTarget, moveCount: state.moveCount));
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
    );
    cancel();
    return picked;
  }

  /// The camera starts moving (a drag, or the map flying to a place).
  void onCameraMoveStarted() {
    if (!isClosed && state.isPicking && !state.isDragging) {
      emit(state.copyWith(isDragging: true));
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

  /// The search box text changed. Google is not asked while typing: Geocoding
  /// answers a whole address, not a few letters, so that search runs only
  /// when the customer submits ([submitSearch]). What shows meanwhile are the
  /// places the customer picked before — read from the device, so free: the
  /// last few while the box is empty, the matching ones while typing.
  /// Clearing the box also drops a search still on its way.
  void queryChanged(String text) {
    if (isClosed) return;
    _typed = text;
    if (text.trim().isEmpty) {
      _query = '';
      _places.cancelSearch();
      emit(state.copyWith(
        suggestions: const [],
        isSearching: false,
        clearSearchError: true,
      ));
      unawaited(_showRecent(text));
      return;
    }
    if (state.searchError != null) emit(state.copyWith(clearSearchError: true));
    unawaited(_showRecent(text));
  }

  /// The customer submitted [query] (the keyboard's search key, or the search
  /// icon). Too short a query asks Google nothing and says so.
  Future<void> submitSearch(String query) async {
    if (isClosed) return;
    if (!PlacesRepository.isSearchable(query)) {
      _query = '';
      _places.cancelSearch();
      emit(state.copyWith(
        suggestions: const [],
        isSearching: false,
        searchError: AppStrings.current.searchMinChars,
      ));
      return;
    }
    // The same query again changes nothing while it is on its way or its
    // answer is on screen; after a failure or an empty answer it is tried
    // again.
    final normalized = PlacesRepository.normalizeQuery(query);
    if (normalized == _query &&
        (state.isSearching || state.suggestions.isNotEmpty)) {
      return;
    }
    _query = normalized;
    emit(state.copyWith(clearSearchError: true));
    await _runSearch(normalized);
  }

  void clearSearch() => queryChanged('');

  /// Hides the results, e.g. when the customer taps the map.
  void dismissSuggestions() {
    if (isClosed || (state.suggestions.isEmpty && state.searchError == null)) {
      return;
    }
    emit(state.copyWith(suggestions: const [], clearSearchError: true));
  }

  void selectSuggestion(PlaceSuggestionModel suggestion) {
    if (isClosed) return;
    _places.cancelSearch();
    unawaited(_places.remember(suggestion));
    _anchor = (
      lat: suggestion.latitude,
      lng: suggestion.longitude,
      address: suggestion.description,
    );
    _centerLat = suggestion.latitude;
    _centerLng = suggestion.longitude;
    emit(state.copyWith(
      address: suggestion.description,
      isResolving: false,
      addressDeferred: false,
      suggestions: const [],
      isSearching: false,
      clearSearchError: true,
    ));
    _moveTo(suggestion.latitude, suggestion.longitude, 17);
  }

  /// Puts the pin on one of the customer's saved places. Without a stored
  /// address, the address under the pin is looked up as for any dragged pin.
  void selectSaved(PickedLocationModel place) {
    if (isClosed) return;
    _places.cancelSearch();
    final address = place.address;
    _anchor = address == null
        ? null
        : (lat: place.latitude, lng: place.longitude, address: address);
    _centerLat = place.latitude;
    _centerLng = place.longitude;
    emit(state.copyWith(
      address: address,
      clearAddress: address == null,
      isResolving: false,
      addressDeferred: false,
      suggestions: const [],
      isSearching: false,
      clearSearchError: true,
    ));
    _moveTo(place.latitude, place.longitude, 17);
    // The map may already be there, in which case it never goes idle again.
    if (address == null) _resolveCenter(reason: 'saved place without address');
  }

  /// Retry button after a failed address lookup.
  void retryResolve() {
    if (!isClosed && state.isPicking) _resolveCenter(reason: 'retry');
  }

  void _moveTo(double lat, double lng, double zoom) {
    emit(state.copyWith(
      moveTarget: PickedLocationModel(latitude: lat, longitude: lng),
      moveZoom: zoom,
      moveCount: state.moveCount + 1,
    ));
  }

  Future<void> _loadUserPosition() async {
    final position = await _location.getPositionIfAllowed();
    if (position != null) {
      _userPosition ??= (lat: position.latitude, lng: position.longitude);
    }
  }

  /// Lists the places the customer picked before for [query] (the last few
  /// when it's empty). While typing, nothing is replaced when none match, so
  /// the previous results stay until the search answers.
  Future<void> _showRecent(String query) async {
    final near = _userPosition ?? (lat: _centerLat, lng: _centerLng);
    final recent = await _places.recentPlaces(
      query: query,
      nearLatitude: near.lat,
      nearLongitude: near.lng,
    );
    // The customer typed on while the places loaded.
    if (isClosed || query != _typed) return;
    if (recent.isEmpty && query.trim().isNotEmpty) return;
    emit(state.copyWith(suggestions: recent));
  }

  Future<void> _runSearch(String query) async {
    if (isClosed) return;
    emit(state.copyWith(isSearching: true));
    final near = _userPosition ?? (lat: _centerLat, lng: _centerLng);
    try {
      final results = await _places.search(
        query,
        nearLatitude: near.lat,
        nearLongitude: near.lng,
        reason: 'submit from the map',
      );
      // Another search was submitted (or the box cleared) while this ran: a
      // newer search owns the list now.
      if (isClosed || query != _query) return;
      emit(state.copyWith(
        suggestions: results,
        isSearching: false,
        // An empty answer says so, instead of leaving the screen unchanged.
        searchError: results.isEmpty ? AppStrings.current.placesNoResults : null,
        clearSearchError: results.isNotEmpty,
      ));
    } on PlacesCancelledException {
      // Replaced by a newer search, which reports for itself.
      return;
    } on PlacesException catch (e) {
      // Google is down, but the places picked before still answer.
      final recent = await _places.recentPlaces(
        query: query,
        nearLatitude: near.lat,
        nearLongitude: near.lng,
      );
      if (isClosed || query != _query) return;
      emit(state.copyWith(
        suggestions: recent,
        isSearching: false,
        searchError: e.message,
      ));
    }
  }

  Future<void> _resolveCenter({required String reason}) async {
    final lat = _centerLat;
    final lng = _centerLng;
    // The pin is still on the place the customer chose (a search result or a
    // saved place): its own name is the right one, and no lookup could
    // improve on it — it would name the street under it instead.
    final anchored = _anchorAddressAt(lat, lng);
    if (anchored != null) {
      emit(state.copyWith(
        address: anchored,
        isResolving: false,
        addressDeferred: false,
      ));
      return;
    }
    emit(state.copyWith(
      clearAddress: true,
      isResolving: true,
      addressDeferred: false,
    ));
    final address = await _places.addressFor(lat, lng, reason: reason);
    // The pin moved on (or the mode ended) while this ran; the newer lookup
    // owns the state now.
    if (isClosed || !state.isPicking || _centerLat != lat || _centerLng != lng) {
      return;
    }
    emit(state.copyWith(address: address, isResolving: false));
  }

  String? _anchorAddressAt(double lat, double lng) {
    final anchor = _anchor;
    if (anchor == null) return null;
    final isSamePlace = (anchor.lat - lat).abs() < _anchorTolerance &&
        (anchor.lng - lng).abs() < _anchorTolerance;
    return isSamePlace ? anchor.address : null;
  }

  @override
  Future<void> close() {
    _places.cancelSearch();
    return super.close();
  }
}
