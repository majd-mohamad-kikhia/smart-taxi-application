import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/trips_remote_data_source.dart';
import '../models/ride_history_model.dart';

/// Structured failure thrown by [TripsRepository].
class TripsException implements Exception {
  final String message;

  const TripsException(this.message);

  @override
  String toString() => message;
}

class TripsRepository {
  final TripsRemoteDataSource _remote;

  const TripsRepository(this._remote);

  Future<RideHistoryPage> getRides({int page = 1, int? statusId}) =>
      _guard(() => _remote.fetchRides(page: page, statusId: statusId));

  Future<RideHistoryModel> getRide(int id, {bool simplify = false}) =>
      _guard(() => _remote.fetchRide(id, simplify: simplify));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      throw TripsException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
