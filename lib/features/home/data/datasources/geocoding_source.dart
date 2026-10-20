import 'package:dio/dio.dart';
import '../models/place_suggestion_model.dart';

/// Something that can find places by name and name a spot on the map: Google
/// Geocoding, OpenStreetMap's Nominatim, or one standing in for the other
/// (`FallbackGeocodingSource`). Failures are `PlacesException`s.
abstract interface class GeocodingSource {
  /// The places found for [query] (an address or a place name typed in full),
  /// at most [limit]; none found is an empty list, not an error.
  /// [cancelToken] cancels the request when a newer search replaces it, which
  /// throws `PlacesCancelledException`.
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  });

  /// The address of the spot ([latitude], [longitude]) in Arabic, or null
  /// when nothing is known there.
  Future<String?> reverseGeocode(double latitude, double longitude);
}
