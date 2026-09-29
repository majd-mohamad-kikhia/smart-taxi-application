import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../../../driver_auth/data/models/driver_vehicle_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/driver_vehicle_remote_data_source.dart';

/// Structured failure thrown by [DriverVehicleRepository], so the Cubit
/// never has to interpret a raw exception.
class DriverVehicleException implements Exception {
  final String message;

  const DriverVehicleException(this.message);

  @override
  String toString() => message;
}

/// Repository for the driver profile's vehicle card. The Cubit talks to
/// this, never to [DriverVehicleRemoteDataSource] directly.
class DriverVehicleRepository {
  final DriverVehicleRemoteDataSource _remoteDataSource;

  const DriverVehicleRepository(this._remoteDataSource);

  /// Returns `null` when the driver has no vehicle registered yet (404
  /// per swagger.json) — that's a valid empty state, not a failure.
  Future<DriverVehicleModel?> getVehicle() async {
    try {
      return await _remoteDataSource.fetchVehicle();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException && error.statusCode == StatusCode.notFound) {
        return null;
      }
      throw DriverVehicleException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
