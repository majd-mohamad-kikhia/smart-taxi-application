import 'package:dio/dio.dart';
import '../../../../core/complaints/complaint_exception.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/customer_complaints_remote_data_source.dart';

/// Repository for customer complaints. Failures surface as
/// [ComplaintException].
class CustomerComplaintsRepository {
  final CustomerComplaintsRemoteDataSource _remoteDataSource;

  const CustomerComplaintsRepository(this._remoteDataSource);

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
