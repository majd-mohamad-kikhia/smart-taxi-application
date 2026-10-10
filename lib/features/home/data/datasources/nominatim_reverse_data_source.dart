import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';

/// Names a dropped pin with OpenStreetMap's Nominatim (free, keyless): the
/// answer's `display_name` already is the full name — the place, its street
/// and area ("محطة بغداد, شارع الجمهورية, الدباغة, ...") — so there is
/// nothing to assemble, only the administrative tail to cut off.
///
/// Deliberately NOT through `ApiClient`/`ApiEndpoints`: it is a public
/// third-party service, and the app's login token must never reach it. The
/// public server is best-effort (no SLA, about 1 request per second, an
/// identifying User-Agent is required), so every failure is just `null` and
/// the caller falls back to Google.
class NominatimReverseDataSource {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  /// How many leading parts of `display_name` are kept: the place, the
  /// street and the area. What follows is district, governorate and country.
  static const _keptParts = 3;

  final Dio _dio;

  NominatimReverseDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {'User-Agent': AppConstants.userAgentPackage},
            ),
          );

  /// The name of the spot ([latitude], [longitude]) in Arabic, or null when
  /// Nominatim knows nothing there or can't be reached.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _dio.get<dynamic>(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude,
          'lon': longitude,
          'accept-language': 'ar',
          'zoom': 18,
        },
      );
      return shorten(response.data);
    } on DioException catch (e) {
      debugPrint(
        'NominatimReverseDataSource: reverse geocode failed (${e.response?.statusCode}): ${e.message}',
      );
      return null;
    }
  }

  /// The first [_keptParts] parts of the answer's `display_name`. Nominatim
  /// answers `{"error": "Unable to geocode"}` with a 200 when there is
  /// nothing at the spot.
  @visibleForTesting
  static String? shorten(dynamic data) {
    final name = data is Map ? data['display_name'] : null;
    if (name is! String) return null;
    final parts = [
      for (final part in name.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.take(_keptParts).join(AppStrings.current.listSeparator);
  }
}
