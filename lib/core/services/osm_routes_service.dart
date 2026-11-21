import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../models/driving_route_model.dart';
import '../utils/polyline_decoder.dart';
import 'route_exception.dart';
import 'routes_provider.dart';

/// Fetches a driving route from an OpenStreetMap router (OSRM): free, with
/// no key. Used for the driver's way to the customer. It knows no live
/// traffic, so its travel time is the free-flow one.
///
/// Uses its own plain [Dio] on purpose: the app's API client injects the
/// user's auth token, which must never be sent to a third-party host.
class OsmRoutesService implements RoutesProvider {
  final Dio _dio;

  OsmRoutesService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.osmRoutingBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              // OpenStreetMap's usage policy asks every client to say who it is.
              headers: {'User-Agent': 'SmartTaxi-App'},
            ),
          );

  @override
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        // OSRM wants longitude first.
        '/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat',
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
          'alternatives': 'false',
          'steps': 'false',
        },
      );
    } on DioException catch (e) {
      debugPrint(
        'OsmRoutesService: request failed (${e.response?.statusCode}): '
        '${e.response?.data ?? e.message}',
      );
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    return _parse(response.data);
  }

  static DrivingRouteModel _parse(dynamic data) {
    final routes = data is Map ? data['routes'] : null;
    final route = routes is List && routes.isNotEmpty ? routes.first : null;
    final geometry = route is Map ? route['geometry'] : null;
    if (route is! Map || geometry is! String || geometry.isEmpty) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    final points = PolylineDecoder.decode(geometry);
    if (points.length < 2) {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
    return DrivingRouteModel(
      points: points,
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}
