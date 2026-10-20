import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../models/place_suggestion_model.dart';
import '../places_exception.dart';
import '../syria_region.dart';
import 'geocoding_source.dart';

/// Place search and pin naming with OpenStreetMap's Nominatim — the stand-in
/// for Google when Google fails (see `FallbackGeocodingSource`).
///
/// It keeps to Nominatim's usage policy, which a public server insists on:
/// one request a second at most (requests are spaced out, never dropped),
/// the app identified in `User-Agent`, and nothing searched while typing.
/// Answers have the same shape as Google's: a place is its name, then the
/// street, area and city it is in; a pin is street, area, city.
class NominatimDataSource implements GeocodingSource {
  /// The policy's limit: a request a second.
  static const Duration minRequestInterval = Duration(seconds: 1);

  static const _userAgent = '${AppConstants.userAgentPackage} (Smart Taxi app)';

  final Dio _dio;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;

  /// The earliest moment the next request may be sent.
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// [dio], [now] and [delay] exist for tests.
  NominatimDataSource({
    Dio? dio,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  }) : _dio =
           dio ??
           Dio(
             // A client of its own: the app's login token must never reach
             // OpenStreetMap.
             BaseOptions(
               baseUrl: AppConstants.osmNominatimBaseUrl,
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 6),
             ),
           ),
       _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) async {
    await _takeTurn(cancelToken);
    try {
      final response = await _dio.get<dynamic>(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'addressdetails': 1,
          'limit': limit,
          'dedupe': 1,
          'accept-language': 'ar',
          'countrycodes': 'sy',
          // Leaning to Latakia, not limited to it: west,north,east,south.
          'viewbox':
              '${SyriaRegion.latakiaWest},${SyriaRegion.latakiaNorth},'
              '${SyriaRegion.latakiaEast},${SyriaRegion.latakiaSouth}',
          'bounded': 0,
        },
        options: Options(headers: const {'User-Agent': _userAgent}),
        cancelToken: cancelToken,
      );
      return parseSearch(response.data, limit: limit);
    } on DioException catch (e) {
      throw _failureOf('search', e);
    }
  }

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    await _takeTurn(null);
    try {
      final response = await _dio.get<dynamic>(
        '/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
          // A street or a building: what a pin can point at.
          'zoom': 18,
          'accept-language': 'ar',
        },
        options: Options(headers: const {'User-Agent': _userAgent}),
      );
      return parseReverse(response.data);
    } on DioException catch (e) {
      throw _failureOf('reverse geocode', e);
    }
  }

  /// Reserves the next free second and waits for it, so requests are spaced
  /// out whoever asks, and however many ask at once. A request cancelled
  /// while it waits is never sent.
  Future<void> _takeTurn(CancelToken? cancelToken) async {
    final now = _now();
    final slot = _nextSlot.isAfter(now) ? _nextSlot : now;
    _nextSlot = slot.add(minRequestInterval);
    final wait = slot.difference(now);
    if (wait > Duration.zero) await _delay(wait);
    if (cancelToken?.isCancelled ?? false) {
      throw const PlacesCancelledException();
    }
  }

  /// The failure of a request, logged without its address.
  static PlacesException _failureOf(String what, DioException e) {
    if (CancelToken.isCancel(e)) return const PlacesCancelledException();
    debugPrint(
      'NominatimDataSource: $what failed '
      '(${e.type.name}, HTTP ${e.response?.statusCode})',
    );
    return PlacesException(AppStrings.current.errPlacesSearch);
  }

  /// The places of a Nominatim search answer: a place without a usable
  /// location is skipped and so are duplicates; at most [limit]. An answer
  /// with nothing in it is an empty list.
  @visibleForTesting
  static List<PlaceSuggestionModel> parseSearch(dynamic data, {int limit = 8}) {
    if (data is! List) {
      throw PlacesException(AppStrings.current.errPlacesSearch);
    }
    final seen = <String>{};
    final places = <PlaceSuggestionModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      final lat = _number(item['lat']);
      final lng = _number(item['lon']);
      if (lat == null || lng == null) continue;
      final description = _describe(item, withName: true);
      if (description == null || !seen.add(description)) continue;
      places.add(
        PlaceSuggestionModel(description: description, latitude: lat, longitude: lng),
      );
      if (places.length >= limit) break;
    }
    return places;
  }

  /// The address of a Nominatim reverse answer: the street, the area and the
  /// city. "Unable to geocode" (nothing known there) is null.
  @visibleForTesting
  static String? parseReverse(dynamic data) {
    if (data is! Map || data['error'] != null) return null;
    return _describe(data, withName: false);
  }

  /// Nominatim sends coordinates as text.
  static double? _number(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  /// A place's name (when [withName]), then the street, the area and the city
  /// it is in, each said once. When Nominatim gave no address parts, its
  /// `display_name` stands in, cleaned.
  static String? _describe(Map item, {required bool withName}) {
    final address = item['address'] is Map ? item['address'] as Map : const {};
    String? first(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final name = withName && item['name'] is String
        ? (item['name'] as String).trim()
        : null;
    final parts = <String>[];
    for (final part in [
      name,
      first(const ['road', 'pedestrian']),
      first(const ['neighbourhood', 'suburb', 'quarter', 'city_district']),
      first(const ['city', 'town', 'village', 'municipality']),
    ]) {
      if (part != null && part.isNotEmpty && !parts.contains(part)) {
        parts.add(part);
      }
    }
    if (parts.isNotEmpty) return parts.join('، ');
    return _cleanDisplayName(item['display_name']);
  }

  /// "a, b, c, سوريا" as "a، b، c": the country is dropped, the commas are
  /// Arabic ones.
  static String? _cleanDisplayName(Object? displayName) {
    if (displayName is! String) return null;
    final parts = displayName
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty && (parts.last == 'سوريا' || parts.last == 'Syria')) {
      parts.removeLast();
    }
    return parts.isEmpty ? null : parts.join('، ');
  }
}
