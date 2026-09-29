import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../datasources/driver_trip_remote_data_source.dart';
import '../models/driver_trip_fare_model.dart';
import '../models/driver_trip_payment_model.dart';

/// Structured failure thrown by [DriverTripRepository], so the Cubit
/// never has to interpret a raw exception.
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

/// Repository for the driver's active-ride screen. The Cubit talks to
/// this, never to [DriverTripRemoteDataSource] directly.
class DriverTripRepository {
  final DriverTripRemoteDataSource _remoteDataSource;

  const DriverTripRepository(this._remoteDataSource);

  Future<void> markArrived(int rideId) =>
      _guard(() => _remoteDataSource.markArrived(rideId));

  Future<void> startRide(int rideId) =>
      _guard(() => _remoteDataSource.startRide(rideId));

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
