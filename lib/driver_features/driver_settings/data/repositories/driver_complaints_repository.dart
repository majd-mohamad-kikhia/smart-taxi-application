import 'package:dio/dio.dart';
import '../../../../core/complaints/complaint_exception.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_complaints_remote_data_source.dart';

/// Repository for driver complaints. The Cubit talks to this, never to
/// [DriverComplaintsRemoteDataSource] directly.
class DriverComplaintsRepository {
  final DriverComplaintsRemoteDataSource _remoteDataSource;

  const DriverComplaintsRepository(this._remoteDataSource);

  Future<void> submitComplaint({
    required String message,
    String? subject,
  }) async {
    try {
      await _remoteDataSource.submitComplaint(
        message: message,
        subject: subject,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw ComplaintException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
