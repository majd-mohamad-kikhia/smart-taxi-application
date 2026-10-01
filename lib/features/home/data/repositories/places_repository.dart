import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/places_remote_data_source.dart';
import '../models/place_suggestion_model.dart';

class PlacesException implements Exception {
  final String message;

  const PlacesException(this.message);

  @override
  String toString() => message;
}

/// Photon-backed search for the location picker (search-as-you-type +
/// naming the dropped pin).
class PlacesRepository {
  final PlacesRemoteDataSource _remoteDataSource;

  const PlacesRepository(this._remoteDataSource);

  /// [nearLatitude]/[nearLongitude] (typically the map's current center)
  /// bias results toward nearby places rather than same-named places
  /// anywhere in the world.
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (query.trim().isEmpty) return const [];
    try {
      return await _remoteDataSource.autocomplete(
        query,
        nearLatitude: nearLatitude,
        nearLongitude: nearLongitude,
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
