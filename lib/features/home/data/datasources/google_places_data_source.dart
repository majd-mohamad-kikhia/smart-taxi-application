import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/google_api_credentials_loader.dart';
import '../models/place_suggestion_model.dart';
import '../places_exception.dart';

/// Place search by name with Google Places API (New) — Text Search — and
/// naming a dropped pin with the Google Geocoding API. Both use the key from
/// `.env` (see `GoogleApiCredentialsLoader`).
///
/// Search is one POST; Latakia comes first, then the rest of Syria:
/// `regionCode: SY`, a box around Latakia as `locationBias`, Arabic names,
/// and the answer ordered Latakia, Syria, elsewhere. A bias, not a limit, so
/// a place elsewhere can still answer when nothing matches in Syria.
///
/// 5 s timeouts; a missing key or a failed request throws a
/// [PlacesException] (the reason Google gave goes to [debugPrint]).
class GooglePlacesDataSource {
  static const _url = 'https://places.googleapis.com/v1/places:searchText';
  static const _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const _fieldMask =
      'places.displayName,places.formattedAddress,places.location';

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

  GooglePlacesDataSource({
    required Future<GoogleApiCredentials> Function() credentials,
    Dio? dio,
  }) : _credentials = credentials,
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
    final credentials = await _requireCredentials();
    try {
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
      _logFailure('search', e);
      throw PlacesException(AppStrings.current.errPlacesSearch);
    }
  }

  /// The address of the spot ([latitude], [longitude]) in Arabic, or null
  /// when Google knows nothing there.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final credentials = await _requireCredentials();
    try {
      final response = await _dio.get<dynamic>(
        _geocodeUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'language': 'ar',
          'key': credentials.apiKey,
        },
        options: Options(headers: credentials.appHeaders),
      );
      return parseGeocode(response.data);
    } on DioException catch (e) {
      _logFailure('reverse geocode', e);
      throw PlacesException(AppStrings.current.errPlacesSearch);
    }
  }

  Future<GoogleApiCredentials> _requireCredentials() async {
    final credentials = await _credentials();
    if (credentials.apiKey.isEmpty) {
      debugPrint('GooglePlacesDataSource: no Google API key available');
      throw PlacesException(AppStrings.current.errPlacesSearch);
    }
    return credentials;
  }

  void _logFailure(String what, DioException e) {
    debugPrint(
      'GooglePlacesDataSource: $what failed (${e.response?.statusCode}): '
      '${e.response?.data ?? e.message}',
    );
  }

  /// The address of an answer from the Geocoding API: the first result that
  /// is a real address (not led by a plus code), cleaned. Geocoding reports a
  /// refused key as `status: REQUEST_DENIED` with a 200, so the status is
  /// checked too.
  @visibleForTesting
  static String? parseGeocode(dynamic data) {
    if (data is! Map) return null;
    final status = data['status'];
    if (status != 'OK') {
      if (status != 'ZERO_RESULTS') {
        debugPrint(
          'GooglePlacesDataSource: reverse geocode answered $status: ${data['error_message']}',
        );
        throw PlacesException(AppStrings.current.errPlacesSearch);
      }
      return null;
    }
    final results = data['results'];
    if (results is! List) return null;
    for (final result in results) {
      if (result is! Map) continue;
      final raw = (result['formatted_address'] as String? ?? '').trim();
      final types = result['types'];
      // A plus code, alone or leading an unnamed building or station
      // ("GQGR+P5M، اللاذقية"), says nothing a customer can use: the street
      // and area further down the list do.
      if ((types is List && types.contains('plus_code')) || _leadingPlusCode.hasMatch(raw)) {
        continue;
      }
      final address = cleanAddress(raw);
      if (address.isEmpty) continue;
      return types is List && types.contains('route')
          ? _withNeighborhood(address, results)
          : address;
    }
    return null;
  }

  /// A street alone ("الجمهورية، اللاذقية") is vague in a big city: the
  /// neighborhood Google also found goes between the street and the city.
  static String _withNeighborhood(String street, List<dynamic> results) {
    for (final result in results) {
      if (result is! Map) continue;
      final types = result['types'];
      if (types is! List || !types.contains('neighborhood')) continue;
      final name = (result['formatted_address'] as String? ?? '').split(RegExp('[،,]')).first.trim();
      final parts = street.split('،').map((p) => p.trim()).toList();
      if (name.isEmpty || parts.contains(name)) return street;
      parts.insert(1, name);
      return parts.join('، ');
    }
    return street;
  }

  static final RegExp _leadingPlusCode = RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,3}');

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
