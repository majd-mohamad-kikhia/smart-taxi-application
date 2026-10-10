import 'package:flutter/foundation.dart';
import '../datasources/google_places_data_source.dart';
import '../datasources/nominatim_reverse_data_source.dart';
import '../models/place_suggestion_model.dart';
import '../place_search_ranker.dart';
import '../places_exception.dart';

export '../places_exception.dart';

/// Google Places search for the location picker (search-as-you-type);
/// Nominatim, then Google Geocoding, for naming the dropped pin.
class PlacesRepository {
  static const int _maxSuggestions = 8;

  final GooglePlacesDataSource _google;

  /// Names a dropped pin first (free, and it knows the place's own name);
  /// Google's geocoding answers when it has nothing.
  final NominatimReverseDataSource _nominatim;

  const PlacesRepository(this._google, this._nominatim);

  /// Places for [query]: Latakia's first, then the rest of Syria, then the
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
    final found = await _google.search(query, limit: _maxSuggestions);
    return GooglePlacesDataSource.latakiaFirst(
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
  }

  /// Best-effort reverse geocode for a dropped/dragged pin — this fires
  /// automatically as the user moves the map, not from an explicit
  /// action, so a failure here just leaves the address unset rather than
  /// surfacing an error; `PickedLocationModel.displayLabel` already
  /// falls back to raw coordinates when the address is null.
  Future<String?> addressFor(double latitude, double longitude) async {
    final named = await _nominatim.reverseGeocode(latitude, longitude);
    if (named != null) return named;
    try {
      return await _google.reverseGeocode(latitude, longitude);
    } on PlacesException catch (e) {
      debugPrint('PlacesRepository: could not name the pin: $e');
      return null;
    }
  }
}
