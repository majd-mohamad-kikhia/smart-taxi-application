import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/google_api_credentials_loader.dart';
import '../models/place_suggestion_model.dart';

/// Place search by name with Google Places API (New) — Text Search. One POST;
/// Latakia comes first, then the rest of Syria: `regionCode: SY`, a box
/// around Latakia as `locationBias`, Arabic names, and the answer ordered
/// Latakia, Syria, elsewhere. A bias, not a limit, so a place elsewhere can still answer
/// when nothing matches in Syria.
///
/// It never throws and never blocks the screen: 5 s timeouts, and any
/// failure is an empty list so the caller falls back to Photon. After a
/// refusal (400 / 401 / 403: API off, bad key) Google is skipped for
/// [_pauseAfterRefusal] instead of failing on every key press.
class GooglePlacesDataSource {
  static const _url = 'https://places.googleapis.com/v1/places:searchText';
  static const _fieldMask =
      'places.displayName,places.formattedAddress,places.location';
  static const _pauseAfterRefusal = Duration(minutes: 5);

  /// The box around Syria.
  static const _syriaLow = {'latitude': 32.3, 'longitude': 35.6};
  static const _syriaHigh = {'latitude': 37.4, 'longitude': 42.4};

  /// The box around Latakia (city and its surroundings): the search is
  /// biased to it, so Latakia's places come first, then the rest of Syria.
  static const _latakiaLow = {'latitude': 35.1, 'longitude': 35.7};
  static const _latakiaHigh = {'latitude': 35.95, 'longitude': 36.3};

  /// 0 for a place in Latakia, 1 for the rest of Syria, 2 for anywhere else:
  /// the order places are shown in (stable within each group).
  static int regionRank(double latitude, double longitude) {
    bool inside(Map<String, double> low, Map<String, double> high) =>
        latitude >= low['latitude']! &&
        latitude <= high['latitude']! &&
        longitude >= low['longitude']! &&
        longitude <= high['longitude']!;
    if (inside(_latakiaLow, _latakiaHigh)) return 0;
    if (inside(_syriaLow, _syriaHigh)) return 1;
    return 2;
  }

  /// [places] with Latakia's first, then the rest of Syria, then the others;
  /// the order inside each group is kept.
  static List<PlaceSuggestionModel> latakiaFirst(
    List<PlaceSuggestionModel> places,
  ) {
    final indexed = places.indexed.toList()
      ..sort((a, b) {
        final byRegion = regionRank(
          a.$2.latitude,
          a.$2.longitude,
        ).compareTo(regionRank(b.$2.latitude, b.$2.longitude));
        return byRegion != 0 ? byRegion : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  final Future<GoogleApiCredentials> Function() _credentials;
  final Dio _dio;
  final DateTime Function() _now;
  DateTime? _pausedUntil;

  GooglePlacesDataSource({
    required Future<GoogleApiCredentials> Function() credentials,
    Dio? dio,
    DateTime Function()? now,
  }) : _credentials = credentials,
       _now = now ?? DateTime.now,
       // A client of its own: the app's login token must never reach Google.
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 5),
               contentType: Headers.jsonContentType,
             ),
           );

  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
  }) async {
    final paused = _pausedUntil;
    if (paused != null && _now().isBefore(paused)) return const [];
    try {
      final credentials = await _credentials();
      if (credentials.apiKey.isEmpty) return const [];
      final response = await _dio.post<dynamic>(
        _url,
        data: {
          'textQuery': query,
          'languageCode': 'ar',
          'regionCode': 'SY',
          'locationBias': {
            'rectangle': {'low': _latakiaLow, 'high': _latakiaHigh},
          },
          'pageSize': limit,
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': credentials.apiKey,
            'X-Goog-FieldMask': _fieldMask,
            ...credentials.appHeaders,
          },
        ),
      );
      return latakiaFirst(parse(response.data));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        _pausedUntil = _now().add(_pauseAfterRefusal);
      }
      debugPrint(
        'GooglePlacesDataSource: search failed ($status): ${e.response?.data ?? e.message}',
      );
      return const [];
    } catch (e) {
      debugPrint('GooglePlacesDataSource: search failed: $e');
      return const [];
    }
  }

  /// The places of an answer: a place without a location is skipped, the
  /// title is the name plus a cleaned address, duplicates are dropped.
  @visibleForTesting
  static List<PlaceSuggestionModel> parse(dynamic data) {
    final places = data is Map ? data['places'] : null;
    if (places is! List) return const [];
    final seen = <String>{};
    final result = <PlaceSuggestionModel>[];
    for (final place in places) {
      if (place is! Map) continue;
      final location = place['location'];
      final lat = location is Map
          ? (location['latitude'] as num?)?.toDouble()
          : null;
      final lng = location is Map
          ? (location['longitude'] as num?)?.toDouble()
          : null;
      if (lat == null || lng == null) continue;
      final name = place['displayName'] is Map
          ? (place['displayName']['text'] as String? ?? '').trim()
          : '';
      final address = cleanAddress(place['formattedAddress'] as String? ?? '');
      final title = [name, address].where((p) => p.isNotEmpty).join('، ');
      if (title.isEmpty || !seen.add(title)) continue;
      result.add(
        PlaceSuggestionModel(description: title, latitude: lat, longitude: lng),
      );
    }
    return result;
  }

  /// Removes a leading plus code ("X258+GH3،") and the trailing "، سوريا".
  @visibleForTesting
  static String cleanAddress(String address) {
    var text = address.trim();
    text = text.replaceFirst(
      RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,3}\s*[،,]?\s*'),
      '',
    );
    text = text.replaceFirst(RegExp(r'\s*[،,]\s*(سوريا|Syria)\s*$'), '');
    return text.trim();
  }
}
