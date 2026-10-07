import 'package:dio/dio.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_active_ride_model.dart';
import '../models/driver_ride_start_model.dart';
import '../models/driver_ride_finish_model.dart';
import '../models/driver_trip_payment_model.dart';
import '../models/driver_trip_vehicle_model.dart';
import '../models/recorded_route_point_model.dart';

/// Remote data source for the driver's active-ride actions (see
/// swagger.json, tag "Driver Rides"). Each action is a plain REST call —
/// the server applies the same atomic status update and side effects as
/// the equivalent `driver:ride_*` socket event.
class DriverTripRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverTripRemoteDataSource(this._dio, this._endpoints);

  /// The driver's current ride, or null when there is none — or when it is
  /// in a state the trip screen can't resume (see [DriverActiveRideModel]).
  Future<DriverActiveRideModel?> fetchActiveRide() async {
    final response = await _dio.get(_endpoints.driverActiveRide);
    final data = (response.data as Map)['data'];
    return data is Map
        ? DriverActiveRideModel.tryParse(Map<String, dynamic>.from(data))
        : null;
  }

  /// The driver's registered car (`GET /api/driver/vehicle`).
  Future<DriverTripVehicleModel> fetchVehicle() async {
    final response = await _dio.get(_endpoints.driverVehicle);
    return DriverTripVehicleModel.fromJson(
      Map<String, dynamic>.from((response.data as Map)['data'] as Map),
    );
  }

  /// accepted → arrived (optional step). Returns the running waiting timer
  /// (`ride.waiting`, `elapsed_seconds` = 0).
  Future<RideWaitingModel?> markArrived(int rideId) async {
    final response = await _dio.post(_endpoints.driverRidePickup(rideId));
    return _waitingOf(response.data);
  }

  /// accepted / arrived → in_progress, with the number of people who got in
  /// when the order has none yet. Returns the stopped waiting timer and the
  /// saved number.
  Future<DriverRideStartModel> startRide(int rideId, {int? passengersCount}) async {
    final response = await _dio.post(
      _endpoints.driverRideStart(rideId),
      data: {'passengers_count': ?passengersCount},
    );
    final data = response.data is Map ? (response.data as Map)['data'] : null;
    return data is Map
        ? DriverRideStartModel.fromRideJson(Map<String, dynamic>.from(data))
        : const DriverRideStartModel();
  }

  /// in_progress → paused (the status stays in_progress). Returns the
  /// running pause: `pause.current.elapsed_seconds` starts at 0.
  Future<RidePauseModel?> pauseRide(int rideId) async {
    final response = await _dio.post(_endpoints.driverRidePause(rideId));
    return _pauseOf(response.data);
  }

  /// paused → in_progress. Returns the pause summary, whose `total_fee`
  /// now includes the pause that just ended.
  Future<RidePauseModel?> resumeRide(int rideId) async {
    final response = await _dio.post(_endpoints.driverRideResume(rideId));
    return _pauseOf(response.data);
  }

  RidePauseModel? _pauseOf(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? RidePauseModel.fromParent(Map<String, dynamic>.from(data)) : null;
  }

  RideWaitingModel? _waitingOf(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? RideWaitingModel.fromParent(Map<String, dynamic>.from(data)) : null;
  }

  /// in_progress → completed. The server prices the trip from the distance
  /// actually driven and returns the final fare.
  Future<DriverRideFinishModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) async {
    final response = await _dio.post(
      _endpoints.driverRideFinish(rideId),
      data: {'distance_km': distanceKm},
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return DriverRideFinishModel.fromRideJson(
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
