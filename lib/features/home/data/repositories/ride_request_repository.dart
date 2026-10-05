import 'package:dio/dio.dart';
import '../../../../core/models/account_block_model.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/ride_request_remote_data_source.dart';
import '../models/restored_ride_model.dart';
import '../models/ride_booking_options_model.dart';
import '../models/ride_quote_model.dart';

class RideRequestException implements Exception {
  final String message;

  /// Set when the server refused the order because ordering is blocked.
  final AccountBlockModel? block;

  const RideRequestException(this.message, {this.block});

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
    required RideBookingOptionsModel options,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    try {
      return await _remoteDataSource.chooseVehicle(
        options: options,
        pickup: pickup,
        dropoff: dropoff,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// The ride the customer was in the middle of when the app last closed,
  /// or null when there is none.
  Future<RestoredRideModel?> fetchActiveRide() async {
    try {
      return await _remoteDataSource.fetchActiveRide();
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
    if (error is! ApiException) {
      return RideRequestException(AppStrings.current.errServerUnreachable);
    }
    final errors = error.rawErrors;
    if (error.statusCode == StatusCode.forbidden && errors?['reason_code'] != null) {
      final block = AccountBlockModel.fromOrderRefusal(errors!);
      return RideRequestException(block.message ?? error.message, block: block);
    }
    return RideRequestException(error.message);
  }
}
