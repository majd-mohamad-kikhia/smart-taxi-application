import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/ride_request_remote_data_source.dart';
import '../models/picked_location_model.dart';

/// Structured failure thrown by [RideRequestRepository], so the Cubit
/// only ever has to catch one exception type.
class RideRequestException implements Exception {
  final String message;

  const RideRequestException(this.message);

  @override
  String toString() => message;
}

/// Repository for the "create ride request" flow.
///
/// The Cubit talks to this, never to [RideRequestRemoteDataSource]
/// directly, so swapping the stub for the real network call later doesn't
/// touch presentation code.
class RideRequestRepository {
  final RideRequestRemoteDataSource _remoteDataSource;

  const RideRequestRepository(this._remoteDataSource);

  Future<void> searchRide({
    required PickedLocationModel from,
    required PickedLocationModel to,
  }) async {
    try {
      await _remoteDataSource.searchRide(from: from, to: to);
    } on DioException catch (e) {
      final error = e.error;
      throw RideRequestException(
        error is ApiException ? error.message : 'تعذر الاتصال بالخادم',
      );
    } on UnimplementedError {
      throw const RideRequestException(
        'ميزة البحث عن رحلة غير متاحة حالياً، سيتم تفعيلها قريباً',
      );
    }
  }
}
