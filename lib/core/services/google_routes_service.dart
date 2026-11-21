import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../models/driving_route_model.dart';
import '../utils/polyline_decoder.dart';
import 'google_api_credentials_loader.dart';
import 'route_exception.dart';
import 'routes_provider.dart';

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
///
/// Every call is billed, so repeats are avoided here: identical requests that
/// are in flight at the same time share one call, and a caller that only needs
/// the road line (not live traffic) can [computeRoute] with `reuseFor` to
/// reuse an answer from the last minutes.
class GoogleRoutesService implements RoutesProvider {
  static const String _fieldMask =
      'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline';

  final Dio _dio;
  final Future<GoogleApiCredentials> Function() _credentials;
  final DateTime Function() _now;

  /// How many answers are kept; the oldest goes first.
  static const int _maxKept = 40;

  /// Answers kept for [computeRoute]'s `reuseFor`, by request.
  final Map<String, ({DateTime at, DrivingRouteModel route})> _answers = {};

  /// Calls on their way, by request: a second identical one waits for the first.
  final Map<String, Future<DrivingRouteModel>> _inFlight = {};

  GoogleRoutesService({
    required Future<GoogleApiCredentials> Function() credentials,
    Dio? dio,
    DateTime Function()? now,
  }) : _credentials = credentials,
       _now = now ?? DateTime.now,
       _dio =
           dio ??
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
  ///
  /// [trafficAware] false asks for the road without live traffic, which
  /// Google bills at about half the price: use it when only the line is
  /// drawn and the travel time is not read. [reuseFor] answers from the last
  /// such call for the same two points (to about 10 m) made within that time.
  @override
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    bool trafficAware = true,
    Duration? reuseFor,
  }) {
    final key = _key(fromLat, fromLng, toLat, toLng, trafficAware);
    if (reuseFor != null) {
      final kept = _answers[key];
      if (kept != null && _now().difference(kept.at) <= reuseFor) {
        return Future.value(kept.route);
      }
    }
    final running = _inFlight[key];
    if (running != null) return running;
    final call = _request(
      fromLat,
      fromLng,
      toLat,
      toLng,
      trafficAware,
    ).then((route) {
      _answers.remove(key);
      _answers[key] = (at: _now(), route: route);
      if (_answers.length > _maxKept) _answers.remove(_answers.keys.first);
      return route;
    }).whenComplete(() {
      // A block, not an arrow: `remove` returns this very future, and
      // whenComplete would wait on it forever.
      _inFlight.remove(key);
    });
    return _inFlight[key] = call;
  }

  static String _key(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    bool trafficAware,
  ) {
    String r(double v) => v.toStringAsFixed(4);
    return '${r(fromLat)},${r(fromLng)}>${r(toLat)},${r(toLng)}'
        '${trafficAware ? '' : ':plain'}';
  }

  Future<DrivingRouteModel> _request(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    bool trafficAware,
  ) async {
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
          // Live-traffic travel time without the slower "optimal" search;
          // without traffic the call is billed at the cheaper tier.
          'routingPreference': trafficAware ? 'TRAFFIC_AWARE' : 'TRAFFIC_UNAWARE',
          // Google's alternatives too: the shortest of them is drawn.
          'computeAlternativeRoutes': true,
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'ENCODED_POLYLINE',
          'units': 'METRIC',
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': credentials.apiKey,
            'X-Goog-FieldMask': _fieldMask,
            ...credentials.appHeaders,
          },
        ),
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
    if (routes is! List || routes.isEmpty) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    // The shortest by distance among the usable routes (Google's own
    // recommendation is the fastest, which is often a little longer). Ties
    // keep Google's order. Its own travel time is the ETA.
    DrivingRouteModel? shortest;
    for (final route in routes) {
      final candidate = route is Map ? _parseRoute(route) : null;
      if (candidate != null &&
          (shortest == null ||
              candidate.distanceMeters < shortest.distanceMeters)) {
        shortest = candidate;
      }
    }
    if (shortest == null) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    return shortest;
  }

  /// One route of the answer, or null when it has no usable polyline.
  static DrivingRouteModel? _parseRoute(Map route) {
    final polyline = route['polyline'];
    final encoded = polyline is Map ? polyline['encodedPolyline'] : null;
    if (encoded is! String || encoded.isEmpty) return null;
    final points = PolylineDecoder.decode(encoded);
    if (points.length < 2) return null;
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
