import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/google_api_credentials_loader.dart';
import '../models/place_suggestion_model.dart';
import '../places_exception.dart';
import '../syria_region.dart';
import 'geocoding_source.dart';

/// Place search by name and the naming of a dropped pin, both with the
/// Google Geocoding API (the key comes from `.env`, see
/// `GoogleApiCredentialsLoader`). Geocoding is not an autocomplete API: it
/// answers a whole address typed in full, so the screens search only when the
/// customer submits (see `PlacesRepository`, which also caches and cancels).
///
/// Search is one GET, Latakia first and then the rest of Syria:
/// `components=country:SY`, `region=sy`, a box around Latakia as `bounds`,
/// Arabic names, and the answer ordered Latakia, Syria, elsewhere. A bias,
/// not a limit.
///
/// 5 s timeouts; a missing key, a refused or failed request throws a
/// [PlacesException]. Nothing is retried, and a failure is logged without the
/// request address, which carries the key.
class GooglePlacesDataSource implements GeocodingSource {
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

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

  /// The places Google finds for [query] (an address or a place name typed
  /// in full), at most [limit]. An answer with no result is an empty list,
  /// not an error. [cancelToken] cancels the request when a newer search
  /// replaces it, which throws [PlacesCancelledException].
  @override
  Future<List<PlaceSuggestionModel>> search(
    String query, {
    int limit = 8,
    CancelToken? cancelToken,
  }) async {
    final credentials = await _requireCredentials();
    try {
      final response = await _dio.get<dynamic>(
        _geocodeUrl,
        queryParameters: {
          'address': query,
          'language': 'ar',
          'region': 'sy',
          'components': 'country:SY',
          // South-west | north-east corner of the Latakia box.
          'bounds':
              '${SyriaRegion.latakiaSouth},${SyriaRegion.latakiaWest}'
              '|${SyriaRegion.latakiaNorth},${SyriaRegion.latakiaEast}',
          'key': credentials.apiKey,
        },
        options: Options(headers: credentials.appHeaders),
        cancelToken: cancelToken,
      );
      return parseSearch(response.data, limit: limit);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw const PlacesCancelledException();
      _logFailure('search', e);
      throw _failureOf(e);
    }
  }

  /// The address of the spot ([latitude], [longitude]) in Arabic, or null
  /// when Google knows nothing there.
  @override
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
      throw _failureOf(e);
    }
  }

  /// The message a failed request ends with. Customers see the plain text; a
  /// debug build adds what Google said (`REQUEST_DENIED`, `HTTP 403`…), so a
  /// blocked key or a disabled API is visible on screen without the console.
  static String _failureMessage(String? detail) {
    final text = AppStrings.current.errPlacesSearch;
    return kDebugMode && detail != null ? '$text ($detail)' : text;
  }

  Future<GoogleApiCredentials> _requireCredentials() async {
    final credentials = await _credentials();
    if (credentials.apiKey.isEmpty) {
      debugPrint('GooglePlacesDataSource: no Google API key available');
      throw PlacesException(_failureMessage('no API key'), persistent: true);
    }
    return credentials;
  }

  /// A refused key (401, 403) or an exhausted quota (429) stays that way for
  /// a while; a dropped connection, a timeout or a server error may not.
  static const _persistentHttpCodes = {401, 403, 429};

  static PlacesException _failureOf(DioException e) {
    final code = e.response?.statusCode;
    return PlacesException(
      _failureMessage(code == null ? e.type.name : 'HTTP $code'),
      persistent: _persistentHttpCodes.contains(code),
    );
  }

  /// Never the request address nor [DioException.message]: both can carry
  /// the key in the query string.
  void _logFailure(String what, DioException e) {
    final body = e.response?.data;
    final reason = body is Map ? body['error_message'] : null;
    debugPrint(
      'GooglePlacesDataSource: $what failed (${e.type.name}, '
      'HTTP ${e.response?.statusCode})${reason == null ? '' : ': $reason'}',
    );
  }

  /// Google's `status` for [data], with the answers that are not a failure
  /// returned as they are (`OK`, `ZERO_RESULTS`). Anything else —
  /// `OVER_QUERY_LIMIT`, `REQUEST_DENIED`, `INVALID_REQUEST`,
  /// `UNKNOWN_ERROR`, or a reply that is not what Geocoding sends — is a
  /// [PlacesException]. Geocoding reports a refused key with a 200, so the
  /// status is read even when the HTTP answer was fine.
  static const _persistentStatuses = {'REQUEST_DENIED', 'OVER_QUERY_LIMIT'};

  static String _statusOf(dynamic data, String what) {
    final status = data is Map ? data['status'] : null;
    if (status == 'OK' || status == 'ZERO_RESULTS') return status as String;
    debugPrint(
      'GooglePlacesDataSource: $what answered $status'
      '${data is Map && data['error_message'] != null ? ': ${data['error_message']}' : ''}',
    );
    throw PlacesException(
      _failureMessage(status is String ? status : 'no status'),
      status: status is String ? status : null,
      persistent: _persistentStatuses.contains(status),
    );
  }

  /// The address components of one Geocoding result, as they came.
  static List<Map<dynamic, dynamic>> _componentsOf(Map result) {
    final components = result['address_components'];
    if (components is! List) return const [];
    return [
      for (final component in components)
        if (component is Map) component,
    ];
  }

  /// The name of the first component with a type that [matches] — found by
  /// type, never by position: which components come, and in what order,
  /// changes from one answer to the next.
  static String? _componentName(
    List<Map<dynamic, dynamic>> components,
    bool Function(String type) matches,
  ) {
    for (final component in components) {
      final types = component['types'];
      if (types is! List || !types.any((t) => t is String && matches(t))) {
        continue;
      }
      final name = (component['long_name'] as String? ?? '').trim();
      if (name.isNotEmpty) return name;
    }
    return null;
  }

  /// The most specific name a result gives itself, in this order of
  /// preference.
  static const _titleTypes = [
    'premise',
    'establishment',
    'point_of_interest',
    'route',
    'neighborhood',
    'sublocality',
    'locality',
  ];

  static String? _titleOf(Map result) {
    final components = _componentsOf(result);
    for (final type in _titleTypes) {
      final name = _componentName(
        components,
        (t) =>
            t == type || (type == 'sublocality' && t.startsWith('sublocality')),
      );
      if (name != null) return name;
    }
    return null;
  }

  /// The places of a Geocoding answer for a search: each result's most
  /// specific name followed by its cleaned address (just the address when it
  /// already starts with that name); a result without a location is skipped
  /// and so are duplicates. At most [limit]. `ZERO_RESULTS` is an empty list.
  @visibleForTesting
  static List<PlaceSuggestionModel> parseSearch(dynamic data, {int limit = 8}) {
    if (_statusOf(data, 'search') == 'ZERO_RESULTS') return const [];
    final results = (data as Map)['results'];
    if (results is! List) return const [];
    final seen = <String>{};
    final places = <PlaceSuggestionModel>[];
    for (final result in results) {
      if (result is! Map) continue;
      final geometry = result['geometry'];
      final location = geometry is Map ? geometry['location'] : null;
      final lat = location is Map
          ? (location['lat'] as num?)?.toDouble()
          : null;
      final lng = location is Map
          ? (location['lng'] as num?)?.toDouble()
          : null;
      if (lat == null || lng == null) continue;
      final title = _titleOf(result);
      final address = cleanAddress(
        result['formatted_address'] as String? ?? '',
      );
      final description = title == null || address.startsWith(title)
          ? (address.isEmpty ? (title ?? '') : address)
          : address.isEmpty
          ? title
          : '$title، $address';
      if (description.isEmpty || !seen.add(description)) continue;
      places.add(
        PlaceSuggestionModel(
          description: description,
          latitude: lat,
          longitude: lng,
        ),
      );
      if (places.length >= limit) break;
    }
    return places;
  }

  /// The address of a Geocoding answer for a pin: the first result that says
  /// something about a street or an area, named from its address components
  /// in this order — the street, then the neighborhood (or sub-locality),
  /// then the city. A plus-code result is never the one. When no result has
  /// such components (a short answer), the first real address in
  /// `formatted_address` stands in, cleaned. `ZERO_RESULTS` is null.
  @visibleForTesting
  static String? parseGeocode(dynamic data) {
    if (data is! Map) return null;
    if (_statusOf(data, 'reverse geocode') == 'ZERO_RESULTS') return null;
    final results = data['results'];
    if (results is! List) return null;
    for (final result in results) {
      if (result is! Map || _isPlusCode(result)) continue;
      final label = _labelFromComponents(result);
      if (label != null) return label;
    }
    return _labelFromFormatted(results);
  }

  static bool _isPlusCode(Map result) {
    final types = result['types'];
    return types is List && types.contains('plus_code');
  }

  /// Street, neighborhood, city — only when there is a street or an area to
  /// say; a city alone is left to the fallback, which may find better.
  static String? _labelFromComponents(Map result) {
    final components = _componentsOf(result);
    final street = _componentName(components, (t) => t == 'route');
    final area =
        _componentName(components, (t) => t == 'neighborhood') ??
        _componentName(components, (t) => t.startsWith('sublocality'));
    if (street == null && area == null) return null;
    final city = _componentName(components, (t) => t == 'locality');
    final parts = <String>[];
    for (final part in [street, area, city]) {
      if (part != null && !parts.contains(part)) parts.add(part);
    }
    return parts.join('، ');
  }

  /// The first result that is a real address (not led by a plus code),
  /// cleaned; a street gets its neighborhood between it and the city.
  static String? _labelFromFormatted(List<dynamic> results) {
    for (final result in results) {
      if (result is! Map || _isPlusCode(result)) continue;
      final raw = (result['formatted_address'] as String? ?? '').trim();
      // A plus code leading an unnamed building or station
      // ("GQGR+P5M، اللاذقية") says nothing a customer can use: the street
      // and area further down the list do.
      if (_leadingPlusCode.hasMatch(raw)) continue;
      final address = cleanAddress(raw);
      if (address.isEmpty) continue;
      final types = result['types'];
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
      final name = (result['formatted_address'] as String? ?? '')
          .split(RegExp('[،,]'))
          .first
          .trim();
      final parts = street.split('،').map((p) => p.trim()).toList();
      if (name.isEmpty || parts.contains(name)) return street;
      parts.insert(1, name);
      return parts.join('، ');
    }
    return street;
  }

  static final RegExp _leadingPlusCode = RegExp(
    r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,3}',
  );

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
