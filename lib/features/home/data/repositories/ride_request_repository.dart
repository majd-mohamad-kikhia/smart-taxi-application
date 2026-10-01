import 'package:dio/dio.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/ride_request_remote_data_source.dart';
import '../models/ride_quote_model.dart';

class RideRequestException implements Exception {
  final String message;

  const RideRequestException(this.message);

  @override
  String toString() => message;
}

/// Every `DioException` has already been turned into a structured
/// [ApiException] by `ApiClient`'s error interceptor, so the mapping here
/// just unwraps its message.
class RideRequestRepository {
  final RideRequestRemoteDataSource _remoteDataSource;

  const RideRequestRepository(this._remoteDataSource);

  /// Order flow step 1 — validates the two pins and returns distance,
  /// ETA and a price per vehicle type. Creates nothing.
  Future<RideQuoteModel> resolveLocations({
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    try {
      return await _remoteDataSource.resolveLocations(
        pickup: pickup,
        dropoff: dropoff,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Order flow step 2 — creates the ride with the chosen vehicle type
  /// and returns it with `status_id = 1` (`requested`).
  Future<RideModel> chooseVehicle({
    required int vehicleTypeId,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    try {
      return await _remoteDataSource.chooseVehicle(
        vehicleTypeId: vehicleTypeId,
        pickup: pickup,
        dropoff: dropoff,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<RideModel> cancelRide({
    required int rideId,
    String? cancellationReason,
  }) async {
    try {
      return await _remoteDataSource.cancelRide(
        rideId: rideId,
        cancellationReason: cancellationReason,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  RideRequestException _mapDioException(DioException e) {
    final error = e.error;
    return RideRequestException(
      error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
    );
  }
}
