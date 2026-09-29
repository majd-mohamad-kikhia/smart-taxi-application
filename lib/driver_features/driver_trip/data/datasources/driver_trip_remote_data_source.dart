import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_trip_fare_model.dart';
import '../models/driver_trip_payment_model.dart';
import '../models/recorded_route_point_model.dart';

/// Remote data source for the driver's active-ride actions (see
/// swagger.json, tag "Driver Rides"). Each action is a plain REST call —
/// the server applies the same atomic status update and side effects as
/// the equivalent `driver:ride_*` socket event.
class DriverTripRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverTripRemoteDataSource(this._dio, this._endpoints);

  /// accepted → arrived (optional step).
  Future<void> markArrived(int rideId) async {
    await _dio.post(_endpoints.driverRidePickup(rideId));
  }

  /// accepted / arrived → in_progress.
  Future<void> startRide(int rideId) async {
    await _dio.post(_endpoints.driverRideStart(rideId));
  }

  /// in_progress → completed. The server prices the trip from the distance
  /// actually driven and returns the final fare.
  Future<DriverTripFareModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) async {
    final response = await _dio.post(
      _endpoints.driverRideFinish(rideId),
      data: {'distance_km': distanceKm},
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return DriverTripFareModel.fromRideJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  /// accepted / arrived / in_progress → cancelled.
  Future<void> cancelRide({
    required int rideId,
    required String cancellationReason,
  }) async {
    await _dio.post(
      _endpoints.driverRideCancel(rideId),
      data: {'cancellation_reason': cancellationReason},
    );
  }

  /// Completed + unpaid → paid: the driver confirms the customer paid cash,
  /// and the server deducts the manager's commission from the driver's
  /// wallet. Works once per ride (a second call is a 409). Returns null if
  /// the reply carries no `payment` block — the confirm itself still
  /// succeeded.
  Future<DriverTripPaymentModel?> confirmPayment(int rideId) async {
    final response = await _dio.post(_endpoints.driverRideConfirmPayment(rideId));
    final body = Map<String, dynamic>.from(response.data as Map);
    final data = body['data'];
    final ride = data is Map && data['ride'] is Map ? data['ride'] : data;
    final payment = ride is Map ? ride['payment'] : null;
    return payment is Map
        ? DriverTripPaymentModel.fromJson(Map<String, dynamic>.from(payment))
        : null;
  }

  /// Uploads the driven route after the ride ended. A PUT, so a retry simply
  /// replaces the earlier upload. Never changes the ride itself.
  Future<void> uploadRoute({
    required int rideId,
    required List<RecordedRoutePointModel> points,
  }) async {
    await _dio.put(
      _endpoints.driverRideRoute(rideId),
      data: {'points': points.map((p) => p.toJson()).toList()},
    );
  }
}
