import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../models/driving_route_model.dart';
import '../utils/polyline_decoder.dart';
import 'google_api_credentials_loader.dart';
import 'route_service.dart' show RouteException;

/// Fetches a driving route — road line, distance and travel time with live
/// traffic — from the Google Routes API.
///
/// Uses its own plain [Dio] on purpose: the app's API client injects the
/// user's auth token, which must never be sent to a third-party host.
///
/// The key and the app identity headers come from
/// [GoogleApiCredentialsLoader]: a key restricted to Android or iOS apps
/// only works when the request says which app it comes from.
///
/// The API bills and answers by field mask, so the request asks for the
/// three fields the map needs and nothing else (no legs, steps or
/// localized text): a small response is a fast one.
class GoogleRoutesService {
  static const String _fieldMask =
      'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline';

  final Dio _dio;
  final Future<GoogleApiCredentials> Function() _credentials;

  GoogleRoutesService({
    required Future<GoogleApiCredentials> Function() credentials,
    Dio? dio,
  })  : _credentials = credentials,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.googleRoutesBaseUrl,
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 8),
                contentType: Headers.jsonContentType,
              ),
            );

  /// The fastest road route from ([fromLat], [fromLng]) to ([toLat], [toLng]).
  ///
  /// Throws [RouteException] when there is no key, no route, or the request
  /// fails — [debugPrint] carries the reason Google gave (a missing Routes
  /// API permission or an unregistered app signature shows up there).
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final credentials = await _credentials();
    if (credentials.apiKey.isEmpty) {
      debugPrint('GoogleRoutesService: no Google API key available');
      throw RouteException(AppStrings.current.errServerUnreachable);
    }

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        AppConstants.googleRoutesComputePath,
        data: {
          'origin': _waypoint(fromLat, fromLng),
          'destination': _waypoint(toLat, toLng),
          'travelMode': 'DRIVE',
          // Live-traffic travel time without the slower "optimal" search.
          'routingPreference': 'TRAFFIC_AWARE',
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'ENCODED_POLYLINE',
          'units': 'METRIC',
        },
        options: Options(headers: {
          'X-Goog-Api-Key': credentials.apiKey,
          'X-Goog-FieldMask': _fieldMask,
          ...credentials.appHeaders,
        }),
      );
    } on DioException catch (e) {
      debugPrint(
        'GoogleRoutesService: request failed (${e.response?.statusCode}): '
        '${e.response?.data ?? e.message}',
      );
      throw RouteException(AppStrings.current.errServerUnreachable);
    }

    return _parse(response.data);
  }

  static Map<String, dynamic> _waypoint(double lat, double lng) => {
        'location': {
          'latLng': {'latitude': lat, 'longitude': lng},
        },
      };

  /// proto3 JSON omits zero values, so a missing distance or duration means
  /// 0 (origin == destination); a missing polyline means no usable route.
  static DrivingRouteModel _parse(dynamic data) {
    final routes = data is Map ? data['routes'] : null;
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    final route = routes.first as Map;
    final polyline = route['polyline'];
    final encoded = polyline is Map ? polyline['encodedPolyline'] : null;
    if (encoded is! String || encoded.isEmpty) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }

    final points = PolylineDecoder.decode(encoded);
    if (points.length < 2) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    return DrivingRouteModel(
      points: points,
      distanceMeters: (route['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: _parseSeconds(route['duration']),
    );
  }

  /// `duration` is a protobuf Duration string such as `"845s"`.
  static double _parseSeconds(dynamic duration) {
    if (duration is! String || !duration.endsWith('s')) return 0;
    return double.tryParse(duration.substring(0, duration.length - 1)) ?? 0;
  }
}
