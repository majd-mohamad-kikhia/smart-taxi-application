import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../datasources/google_places_data_source.dart';
import '../datasources/recent_places_local_data_source.dart';
import '../models/place_suggestion_model.dart';
import '../place_search_ranker.dart';
import '../places_exception.dart';

export '../places_exception.dart';

/// Google Places search for the location picker (search-as-you-type);
/// Google Geocoding for naming the dropped pin; and the places the customer
/// picked before, kept on the device, which come first in every search.
class PlacesRepository {
  static const int _maxSuggestions = 8;

  /// How many recent places are kept on the device.
  static const int maxRecent = 100;

  /// How many recent places answer a typed search, and how many are listed
  /// while the search box is empty.
  static const int _maxRecentMatches = 3;
  static const int _maxRecentListed = 5;

  final GooglePlacesDataSource _google;
  final RecentPlacesLocalDataSource _recent;

  const PlacesRepository(this._google, this._recent);

  /// Places for [query]: the customer's recent picks that match it first,
  /// then Google's — Latakia's first, then the rest of Syria, then the
  /// others; inside each group, those that match what was typed come before
  /// loosely related ones, each by distance from ([nearLatitude],
  /// [nearLongitude]) — pass the customer's own position, not the map's
  /// center, so "nearest to me" means the customer. Without a position
  /// there is nothing to rank by and Google's own order is kept.
  ///
  /// Throws [PlacesException] when Google can't answer.
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (query.trim().isEmpty) return const [];
    final recent = await recentPlaces(
      query: query,
      nearLatitude: nearLatitude,
      nearLongitude: nearLongitude,
    );
    final found = await _google.search(query, limit: _maxSuggestions);
    final fresh = GooglePlacesDataSource.latakiaFirst(
      nearLatitude == null || nearLongitude == null
          ? found
          : PlaceSearchRanker.rank(
              query,
              found,
              fromLatitude: nearLatitude,
              fromLongitude: nearLongitude,
              limit: _maxSuggestions,
            ),
    );
    return [
      ...recent,
      for (final place in fresh)
        if (!recent.any((r) => PlaceSearchRanker.isSamePlace(r, place))) place,
    ];
  }

  /// The places the customer picked before, newest first: the last few when
  /// [query] is empty, otherwise up to three that match it. Each carries its
  /// distance from ([nearLatitude], [nearLongitude]) when those are known.
  Future<List<PlaceSuggestionModel>> recentPlaces({
    String query = '',
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    final saved = await _recent.load();
    final isTyping = query.trim().isNotEmpty;
    final picked = isTyping
        ? saved.where((p) => PlaceSearchRanker.matches(query, p)).take(_maxRecentMatches)
        : saved.take(_maxRecentListed);
    return [
      for (final place in picked)
        nearLatitude == null || nearLongitude == null
            ? place.asRecent()
            : place.asRecent().withDistance(Geolocator.distanceBetween(
                nearLatitude,
                nearLongitude,
                place.latitude,
                place.longitude,
              )),
    ];
  }

  /// Keeps [place] on the device as the newest recent pick (a place picked
  /// again moves to the front). Best-effort: a storage failure must not
  /// stop the customer from choosing the place.
  Future<void> remember(PlaceSuggestionModel place) async {
    try {
      final saved = await _recent.load();
      final updated = [
        place.asRecent(),
        for (final p in saved)
          if (!PlaceSearchRanker.isSamePlace(p, place)) p,
      ];
      await _recent.save(updated.take(maxRecent).toList());
    } catch (e) {
      debugPrint('PlacesRepository: could not remember the place: $e');
    }
  }

  /// Forgets every recent place, e.g. on logout.
  Future<void> clearRecent() => _recent.clear();

  /// Best-effort reverse geocode for a dropped/dragged pin — this fires
  /// automatically as the user moves the map, not from an explicit
  /// action, so a failure here just leaves the address unset rather than
  /// surfacing an error; `PickedLocationModel.displayLabel` already
  /// falls back to raw coordinates when the address is null.
  Future<String?> addressFor(double latitude, double longitude) async {
    try {
      return await _google.reverseGeocode(latitude, longitude);
    } on PlacesException catch (e) {
      debugPrint('PlacesRepository: could not name the pin: $e');
      return null;
    }
  }
}
