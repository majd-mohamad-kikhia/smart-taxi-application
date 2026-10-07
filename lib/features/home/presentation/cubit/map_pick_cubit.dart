import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
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
  static const _searchDebounce = Duration(milliseconds: 400);

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

  Timer? _debounce;
  String _query = '';

  MapPickCubit(this._places, this._location) : super(const MapPickState());

  /// Starts picking [target]. [initial] is the point already chosen for it:
  /// the map moves there. Without one, the pin starts where the map is.
  void enter(
    PickTarget target, {
    PickedLocationModel? initial,
    bool autofocusSearch = false,
  }) {
    if (isClosed) return;
    _query = '';
    _anchor = initial?.address == null
        ? null
        : (lat: initial!.latitude, lng: initial.longitude, address: initial.address!);
    emit(MapPickState(
      target: target,
      autofocusSearch: autofocusSearch,
      address: initial?.address,
      moveTarget: state.moveTarget,
      moveCount: state.moveCount,
    ));
    unawaited(_loadUserPosition());
    if (initial != null) {
      _centerLat = initial.latitude;
      _centerLng = initial.longitude;
      _moveTo(initial.latitude, initial.longitude, 16);
    } else {
      _resolveCenter();
    }
  }

  /// Leaves the mode without choosing anything.
  void cancel() {
    if (isClosed) return;
    _debounce?.cancel();
    _query = '';
    _anchor = null;
    emit(MapPickState(moveTarget: state.moveTarget, moveCount: state.moveCount));
  }

  /// Leaves the mode with the point under the pin, or returns null (and stays)
  /// while there is no resolved address to confirm.
  PickedLocationModel? confirm({String? details}) {
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
    if (!isClosed && state.isPicking) _resolveCenter();
  }

  void search(String query) {
    _debounce?.cancel();
    _query = query;
    if (isClosed) return;
    if (query.trim().isEmpty) {
      emit(state.copyWith(
        suggestions: const [],
        isSearching: false,
        clearSearchError: true,
      ));
      return;
    }
    emit(state.copyWith(clearSearchError: true));
    _debounce = Timer(_searchDebounce, () => _runSearch(query));
  }

  void clearSearch() => search('');

  /// Hides the results, e.g. when the customer taps the map.
  void dismissSuggestions() {
    if (isClosed || (state.suggestions.isEmpty && state.searchError == null)) {
      return;
    }
    emit(state.copyWith(suggestions: const [], clearSearchError: true));
  }

  void selectSuggestion(PlaceSuggestionModel suggestion) {
    if (isClosed) return;
    _debounce?.cancel();
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
    _debounce?.cancel();
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
      suggestions: const [],
      isSearching: false,
      clearSearchError: true,
    ));
    _moveTo(place.latitude, place.longitude, 17);
    // The map may already be there, in which case it never goes idle again.
    if (address == null) _resolveCenter();
  }

  /// Retry button after a failed address lookup.
  void retryResolve() {
    if (!isClosed && state.isPicking) _resolveCenter();
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

  Future<void> _runSearch(String query) async {
    if (isClosed) return;
    emit(state.copyWith(isSearching: true));
    final near = _userPosition ?? (lat: _centerLat, lng: _centerLng);
    try {
      final results = await _places.search(
        query,
        nearLatitude: near.lat,
        nearLongitude: near.lng,
      );
      // The customer typed on (or cleared the box) while this ran: a newer
      // search owns the list now.
      if (isClosed || query != _query) return;
      emit(state.copyWith(suggestions: results, isSearching: false));
    } on PlacesException catch (e) {
      if (isClosed || query != _query) return;
      emit(state.copyWith(
        suggestions: const [],
        isSearching: false,
        searchError: e.message,
      ));
    }
  }

  Future<void> _resolveCenter() async {
    final lat = _centerLat;
    final lng = _centerLng;
    emit(state.copyWith(clearAddress: true, isResolving: true));
    final address = await _places.addressFor(lat, lng);
    // The pin moved on (or the mode ended) while this ran; the newer lookup
    // owns the state now.
    if (isClosed || !state.isPicking || _centerLat != lat || _centerLng != lng) {
      return;
    }
    emit(state.copyWith(
      address: address ?? _anchorAddressAt(lat, lng),
      isResolving: false,
    ));
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
    _debounce?.cancel();
    return super.close();
  }
}
