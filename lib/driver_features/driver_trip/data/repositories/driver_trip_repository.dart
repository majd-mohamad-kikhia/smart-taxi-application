import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../datasources/driver_trip_remote_data_source.dart';
import '../models/driver_active_ride_model.dart';
import '../models/driver_ride_start_model.dart';
import '../models/driver_ride_finish_model.dart';
import '../models/driver_trip_payment_model.dart';
import '../models/driver_trip_vehicle_model.dart';

class DriverTripException implements Exception {
  final String message;
  final int? statusCode;

  /// The server was never heard from (offline, timeout): nothing was
  /// refused, so the same call is safe to send again.
  final bool isNetwork;

  const DriverTripException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
  });

  /// The ride is not in the state this action needs (e.g. payment already
  /// confirmed).
  bool get isConflict => statusCode == StatusCode.conflict;

  @override
  String toString() => message;
}

class DriverTripRepository {
  final DriverTripRemoteDataSource _remoteDataSource;

  /// How long a finish may take before the driver is told it did not go
  /// through. The HTTP client has its own timeouts; this is the hard stop.
  final Duration finishTimeout;

  const DriverTripRepository(
    this._remoteDataSource, {
    this.finishTimeout = const Duration(seconds: 15),
  });

  Future<DriverActiveRideModel?> fetchActiveRide() =>
      _guard(_remoteDataSource.fetchActiveRide);

  Future<DriverTripVehicleModel> fetchVehicle() =>
      _guard(_remoteDataSource.fetchVehicle);

  Future<RideWaitingModel?> markArrived(int rideId) =>
      _guard(() => _remoteDataSource.markArrived(rideId));

  Future<DriverRideStartModel> startRide(int rideId, {int? passengersCount}) => _guard(
    () => _remoteDataSource.startRide(rideId, passengersCount: passengersCount),
  );

  Future<RidePauseModel?> pauseRide(int rideId) =>
      _guard(() => _remoteDataSource.pauseRide(rideId));

  Future<RidePauseModel?> resumeRide(int rideId) =>
      _guard(() => _remoteDataSource.resumeRide(rideId));

  Future<DriverRideFinishModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) => _guard(
    () => _remoteDataSource
        .finishRide(rideId: rideId, distanceKm: distanceKm)
        .timeout(finishTimeout),
  );

  /// After a finish was refused with 409 ("Ride cannot be finished"): the
  /// earlier call may have worked. Returns the finished ride if the server
  /// has it completed, else null.
  Future<DriverRideFinishModel?> fetchFinishedActiveRide() => _guard(
    () => _remoteDataSource.fetchFinishedActiveRide().timeout(finishTimeout),
  );

  Future<DriverTripPaymentModel?> confirmPayment(int rideId) =>
      _guard(() => _remoteDataSource.confirmPayment(rideId));

  Future<void> cancelRide({
    required int rideId,
    required String cancellationReason,
  }) => _guard(
    () => _remoteDataSource.cancelRide(
      rideId: rideId,
      cancellationReason: cancellationReason,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      final statusCode = error is ApiException ? error.statusCode : null;
      throw DriverTripException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
        statusCode: statusCode,
        isNetwork: statusCode == null,
      );
    } on TimeoutException {
      throw DriverTripException(AppStrings.current.errTimeout, isNetwork: true);
    } on DriverTripException {
      rethrow;
    } catch (e) {
      // An answer the app could not read must end the spinner like any other
      // failure, never leave it running.
      debugPrint('DriverTripRepository: unexpected failure: $e');
      throw DriverTripException(AppStrings.current.errUnexpected);
    }
  }
}
