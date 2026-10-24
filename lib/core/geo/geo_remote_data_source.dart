import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_endpoints.dart';
import 'geo_exception.dart';
import 'geo_models.dart';

/// Geo v2 (swagger tag "Geo v2"): every place search, pin label and route
/// fare of the app goes through our server, which asks Google as rarely as
/// it can. The app never calls Google's web services itself.
///
/// A failure is a typed [GeoException]; nothing is retried here.
class GeoRemoteDataSource {
  /// Latakia, the only region.
  static const int region = 1;

  final Dio _dio;
  final ApiEndpoints _endpoints;

  const GeoRemoteDataSource(this._dio, this._endpoints);

  /// Typing suggestions: never reach Google, so they are free.
  Future<List<GeoSuggestionModel>> suggest(
    String query, {
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.get<Object?>(
        _endpoints.geoSuggest,
        queryParameters: {'q': query, 'region': region},
        cancelToken: cancelToken,
      );
      return [
        for (final item in _unwrapList(response.data))
          GeoSuggestionModel.fromJson((item as Map).cast<String, dynamic>()),
      ];
    });
  }

  /// Text (or a tapped suggestion's [aliasId]) → a point.
  Future<GeoResolveResult> resolve(
    String query, {
    int? aliasId,
    bool forceGoogle = false,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.post<Object?>(
        _endpoints.geoResolve,
        data: {
          'q': query,
          'region': region,
          'alias_id': ?aliasId,
          'force_google': forceGoogle,
        },
        cancelToken: cancelToken,
      );
      return GeoResolveResult.fromJson(_unwrapMap(response.data));
    });
  }

  /// Tells the server the customer confirmed (or rejected) a resolved point.
  /// Fire and forget: the answer changes nothing for the customer.
  Future<void> sendFeedback({
    required int aliasId,
    required bool accepted,
  }) async {
    try {
      await _dio.post<Object?>(
        _endpoints.geoResolveFeedback,
        data: {'alias_id': aliasId, 'accepted': accepted},
      );
    } on DioException {
      // Unknown alias (404) or no connection: nothing to do.
    }
  }

  /// The label under a pin, or null (budget reached, Google error).
  Future<String?> reverse(double lat, double lng) {
    return _guard(() async {
      final response = await _dio.post<Object?>(
        _endpoints.geoReverse,
        data: {'lat': lat, 'lng': lng},
      );
      final label = _unwrapMap(response.data)['label'] as String?;
      return label == null || label.trim().isEmpty ? null : label.trim();
    });
  }

  /// The fare of the route, once, when the customer presses Request.
  Future<GeoRouteQuoteModel> routeQuote({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String idempotencyKey,
    int? vehicleTypeId,
    double? fareEst,
  }) {
    return _guard(() async {
      final response = await _dio.post<Object?>(
        _endpoints.geoRouteQuote,
        data: {
          'origin': {'lat': fromLat, 'lng': fromLng},
          'destination': {'lat': toLat, 'lng': toLng},
          'idempotency_key': idempotencyKey,
          'vehicle_type_id': ?vehicleTypeId,
          'fare_est': ?fareEst,
          'include_polyline': true,
        },
      );
      return GeoRouteQuoteModel.fromJson(_unwrapMap(response.data));
    });
  }

  /// The answer as the swagger documents it, or inside the `data` envelope
  /// the rest of the API uses.
  Map<String, dynamic> _unwrapMap(Object? body) {
    final map = (body as Map).cast<String, dynamic>();
    final inner = map['data'];
    return inner is Map ? inner.cast<String, dynamic>() : map;
  }

  List<dynamic> _unwrapList(Object? body) =>
      body is Map ? body['data'] as List : body as List;

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final failure = _failureOf(e);
      debugPrint(
        'GeoRemoteDataSource: ${e.requestOptions.path} failed '
        '(${e.response?.statusCode ?? e.type.name} → ${failure.failure.name})',
      );
      throw failure;
    } on GeoException {
      rethrow;
    } on Object catch (e) {
      // An answer that is not what the swagger documents.
      debugPrint('GeoRemoteDataSource: unreadable answer ($e)');
      throw const GeoException(GeoFailure.server);
    }
  }

  GeoException _failureOf(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final said = body is Map
        ? (body['code'] ?? body['message'] ?? '').toString()
        : '';
    final detail = status == null
        ? e.type.name
        : '$status${said.isEmpty ? '' : ' $said'}';
    switch (e.type) {
      case DioExceptionType.cancel:
        return const GeoException(GeoFailure.cancelled);
      case DioExceptionType.connectionError:
        return GeoException(GeoFailure.offline, detail: detail);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 429) {
          return GeoException(
            _code(e.response?.data) == 'GOOGLE_DAILY_CAP'
                ? GeoFailure.googleDailyCap
                : GeoFailure.rateLimited,
            detail: detail,
          );
        }
        if (status == 502 || status == 503) {
          return GeoException(GeoFailure.googleUnavailable, detail: detail);
        }
        return GeoException(GeoFailure.server, detail: detail);
      default:
        return GeoException(GeoFailure.server, detail: detail);
    }
  }

  String? _code(Object? body) =>
      body is Map && body['code'] is String ? body['code'] as String : null;
}
