import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../models/route_point_model.dart';

/// Structured failure thrown by [RouteService].
class RouteException implements Exception {
  final String message;

  const RouteException(this.message);

  @override
  String toString() => message;
}

/// Fetches the driving route between two points from the routing service
/// (OSRM — see [AppConstants.routingBaseUrl]).
///
/// Uses its own plain [Dio] on purpose: the app's API client injects the
/// user's auth token, which must never be sent to a third-party host.
class RouteService {
  final Dio _dio;

  RouteService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.routingBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  /// The road route from ([fromLat], [fromLng]) to ([toLat], [toLng]),
  /// as an ordered list of points.
  Future<List<RoutePointModel>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final response = await _dio.get(
        '/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat',
        queryParameters: {'overview': 'full', 'geometries': 'geojson'},
      );
      final routes = (response.data as Map)['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw RouteException(AppStrings.current.errServerUnreachable);
      }
      final coordinates =
          ((routes.first as Map)['geometry'] as Map)['coordinates'] as List;
      return [
        for (final c in coordinates)
          RoutePointModel(
            ((c as List)[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ),
      ];
    } on DioException {
      throw RouteException(AppStrings.current.errServerUnreachable);
    }
  }
}
