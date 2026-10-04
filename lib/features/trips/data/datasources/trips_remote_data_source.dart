import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ride_history_model.dart';

/// Remote data source for the customer's ride history — talks to
/// `GET /api/customer/rides` and `GET /api/customer/rides/{id}`.
class TripsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const TripsRemoteDataSource(this._dio, this._endpoints);

  Future<RideHistoryPage> fetchRides({
    int page = 1,
    int limit = 20,
    int? statusId,
  }) async {
    final response = await _dio.get(
      _endpoints.customerRides,
      queryParameters: {
        'page': page,
        'limit': limit,
        'status_id': ?statusId,
      },
    );
    return RideHistoryPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// [simplify] asks the server for a thinned route (fewer points, same
  /// shape) — enough for the small map on the details screen.
  Future<RideHistoryModel> fetchRide(int id, {bool simplify = false}) async {
    final response = await _dio.get(
      _endpoints.customerRideById(id),
      queryParameters: {if (simplify) 'simplify': true},
    );
    return RideHistoryModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// `POST /api/customer/rides/{id}/cancel` — also for a scheduled ride
  /// (no cancel strike for those).
  Future<void> cancelRide(int id, {String? cancellationReason}) {
    return _dio.post(
      _endpoints.customerRideCancel(id),
      data: {'cancellation_reason': ?cancellationReason},
    );
  }
}
