import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../../../../core/utils/parse_utc_date.dart';
import '../../../driver_trip/data/models/driver_active_ride_model.dart';
import '../datasources/shared_order_remote_data_source.dart';
import '../models/shared_order_preview_model.dart';

class SharedOrderException implements Exception {
  final String message;
  final int? statusCode;

  /// `errors.availability` of a 409 / 422 / 403: why the order can't be
  /// taken (e.g. `taken`), or null when the server didn't say.
  final SharedOrderAvailability? availability;

  /// `errors.opens_at` of a `scheduled` refusal (UTC).
  final DateTime? opensAt;

  const SharedOrderException(
    this.message, {
    this.statusCode,
    this.availability,
    this.opensAt,
  });

  bool get isInvalidLink => statusCode == StatusCode.notFound;

  /// No answer from the server (offline, timeout) — safe to try again.
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}

class SharedOrderRepository {
  final SharedOrderRemoteDataSource _remoteDataSource;

  const SharedOrderRepository(this._remoteDataSource);

  Future<SharedOrderPreviewModel> preview(String token) =>
      _guard(() => _remoteDataSource.preview(token));

  Future<DriverActiveRideModel?> accept(String token) =>
      _guard(() => _remoteDataSource.accept(token));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      if (error is! ApiException) {
        throw SharedOrderException(AppStrings.current.errServerUnreachable);
      }
      final availability = error.rawErrors?['availability'];
      final opensAt = error.rawErrors?['opens_at'];
      throw SharedOrderException(
        error.message,
        statusCode: error.statusCode,
        availability: availability == null
            ? null
            : SharedOrderAvailability.fromWire(availability),
        opensAt: opensAt == null ? null : parseUtcDateTime(opensAt),
      );
    }
  }
}
