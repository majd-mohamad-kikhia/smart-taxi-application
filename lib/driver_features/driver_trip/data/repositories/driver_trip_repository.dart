import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../datasources/driver_trip_remote_data_source.dart';
import '../models/driver_active_ride_model.dart';
import '../models/driver_trip_fare_model.dart';
import '../models/driver_trip_payment_model.dart';

class DriverTripException implements Exception {
  final String message;
  final int? statusCode;

  const DriverTripException(this.message, {this.statusCode});

  /// The ride is not in the state this action needs (e.g. payment already
  /// confirmed).
  bool get isConflict => statusCode == StatusCode.conflict;

  @override
  String toString() => message;
}

class DriverTripRepository {
  final DriverTripRemoteDataSource _remoteDataSource;

  const DriverTripRepository(this._remoteDataSource);

  Future<DriverActiveRideModel?> fetchActiveRide() =>
      _guard(_remoteDataSource.fetchActiveRide);

  Future<RideWaitingModel?> markArrived(int rideId) =>
      _guard(() => _remoteDataSource.markArrived(rideId));

  Future<RideWaitingModel?> startRide(int rideId) =>
      _guard(() => _remoteDataSource.startRide(rideId));

  Future<RidePauseModel?> pauseRide(int rideId) =>
      _guard(() => _remoteDataSource.pauseRide(rideId));

  Future<RidePauseModel?> resumeRide(int rideId) =>
      _guard(() => _remoteDataSource.resumeRide(rideId));

  Future<DriverTripFareModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) => _guard(
    () => _remoteDataSource.finishRide(rideId: rideId, distanceKm: distanceKm),
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
      throw DriverTripException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
        statusCode: error is ApiException ? error.statusCode : null,
      );
    }
  }
}
