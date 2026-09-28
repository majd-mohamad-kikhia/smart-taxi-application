import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/place_suggestion_model.dart';

/// Talks to Photon (komoot.io's free, keyless OSM-based geocoder) for
/// live search-as-you-type suggestions and reverse geocoding.
///
/// Deliberately NOT through `ApiClient`/`ApiEndpoints` — this is a
/// separate public service, not your own backend. Free and requires no
/// API key/account, but it's a public best-effort instance (no SLA), so
/// occasional failures under load are expected and handled by the
/// repository layer rather than treated as bugs.
class PlacesRemoteDataSource {
  static const _baseUrl = 'https://photon.komoot.io';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      headers: {'User-Agent': AppConstants.userAgentPackage},
    ),
  );

  Future<List<PlaceSuggestionModel>> autocomplete(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/',
      queryParameters: {
        'q': query,
        'limit': 8,
        'lat': ?nearLatitude,
        'lon': ?nearLongitude,
      },
    );
    final features = response.data?['features'] as List? ?? [];
    return features
        .map((f) => _toSuggestion(f as Map<String, dynamic>))
        .whereType<PlaceSuggestionModel>()
        .toList();
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {'lat': latitude, 'lon': longitude},
    );
    final features = response.data?['features'] as List? ?? [];
    if (features.isEmpty) return null;
    return _toSuggestion(features.first as Map<String, dynamic>)?.description;
  }

  PlaceSuggestionModel? _toSuggestion(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List?;
    if (coordinates == null || coordinates.length < 2) return null;

    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final description = _buildDescription(properties);
    if (description.isEmpty) return null;

    return PlaceSuggestionModel(
      description: description,
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }

  /// Builds a human-readable label from Photon's OSM tag properties
  /// (name, street, city, state, country), skipping blank/duplicate
  /// parts — e.g. a city-level result where `name` already equals `city`.
  String _buildDescription(Map<String, dynamic> properties) {
    String? field(String key) {
      final value = properties[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final streetLine = [field('housenumber'), field('street')]
        .whereType<String>()
        .join(' ');

    final parts = <String>[
      if (field('name') != null) field('name')!,
      if (streetLine.isNotEmpty) streetLine,
      if (field('city') != null) field('city')!,
      if (field('state') != null && field('state') != field('city'))
        field('state')!,
      if (field('country') != null) field('country')!,
    ];

    final seen = <String>{};
    return parts.where((p) => seen.add(p)).join('، ');
  }
}
