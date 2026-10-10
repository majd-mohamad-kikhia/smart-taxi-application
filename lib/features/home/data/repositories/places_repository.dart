import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/google_places_data_source.dart';
import '../datasources/places_remote_data_source.dart';
import '../models/place_suggestion_model.dart';
import '../place_search_ranker.dart';

class PlacesException implements Exception {
  final String message;

  const PlacesException(this.message);

  @override
  String toString() => message;
}

/// Google Places search (Photon as the fallback) for the location picker (search-as-you-type +
/// naming the dropped pin).
class PlacesRepository {
  /// The first search only looks this far around the customer (~55 km).
  static const double _nearbyDegrees = 0.5;
  static const int _nearbyLimit = 20;

  /// Fewer matching places than this nearby, and the search widens to the
  /// whole country/world (still ranked nearest-first).
  static const int _enoughNearbyMatches = 5;
  static const int _widerLimit = 10;
  static const int _maxSuggestions = 8;

  final PlacesRemoteDataSource _remoteDataSource;

  /// Google Places, tried first; Photon answers when Google gives nothing.
  final GooglePlacesDataSource? _google;

  const PlacesRepository(this._remoteDataSource, [this._google]);

  /// Places for [query], nearest to ([nearLatitude], [nearLongitude]) first
  /// — pass the customer's own position, not the map's center, so "nearest
  /// to me" means the customer. Places that match what was typed come
  /// before loosely related ones, each group by distance.
  ///
  /// One request in the common case: it looks only around the customer.
  /// Only when that finds fewer than [_enoughNearbyMatches] matches does a
  /// second, unrestricted request add the farther ones. Without a position
  /// there is nothing to rank by and the service's own order is kept.
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (query.trim().isEmpty) return const [];
    final fromGoogle = await _google?.search(query, limit: _maxSuggestions) ?? const [];
    if (fromGoogle.isNotEmpty) {
      // Latakia first, then the rest of Syria; inside each, nearest first.
      return GooglePlacesDataSource.latakiaFirst(
        nearLatitude == null || nearLongitude == null
            ? fromGoogle
            : PlaceSearchRanker.rank(
                query,
                fromGoogle,
                fromLatitude: nearLatitude,
                fromLongitude: nearLongitude,
                limit: _maxSuggestions,
              ),
      );
    }
    try {
      if (nearLatitude == null || nearLongitude == null) {
        return await _remoteDataSource.autocomplete(query);
      }

      final nearby = await _remoteDataSource.autocomplete(
        query,
        nearLatitude: nearLatitude,
        nearLongitude: nearLongitude,
        withinDegrees: _nearbyDegrees,
        limit: _nearbyLimit,
      );
      var found = nearby;
      if (PlaceSearchRanker.countMatches(query, nearby) < _enoughNearbyMatches) {
        try {
          final wider = await _remoteDataSource.autocomplete(
            query,
            nearLatitude: nearLatitude,
            nearLongitude: nearLongitude,
            limit: _widerLimit,
          );
          found = [...nearby, ...wider];
        } on DioException catch (e) {
          // The nearby places are already a useful answer; only with
          // nothing to show does the failure reach the customer.
          if (nearby.isEmpty) rethrow;
          debugPrint('PlacesRepository: wider search failed: $e');
        }
      }
      return PlaceSearchRanker.rank(
        query,
        found,
        fromLatitude: nearLatitude,
        fromLongitude: nearLongitude,
        limit: _maxSuggestions,
      );
    } on DioException {
      throw PlacesException(AppStrings.current.errPlacesSearch);
    }
  }

  /// Best-effort reverse geocode for a dropped/dragged pin — this fires
  /// automatically as the user moves the map, not from an explicit
  /// action, so a failure here just leaves the address unset rather than
  /// surfacing an error; `PickedLocationModel.displayLabel` already
  /// falls back to raw coordinates when the address is null.
  Future<String?> addressFor(double latitude, double longitude) async {
    try {
      return await _remoteDataSource.reverseGeocode(latitude, longitude);
    } on DioException {
      return null;
    }
  }
}
