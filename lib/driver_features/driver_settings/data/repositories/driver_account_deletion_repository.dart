import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_account_deletion_remote_data_source.dart';
import '../models/driver_deletion_request_model.dart';

/// Repository for the driver's account-deletion request. Failures surface
/// as [ApiException] so the Cubit never sees a raw `DioException`.
class DriverAccountDeletionRepository {
  final DriverAccountDeletionRemoteDataSource _remote;

  const DriverAccountDeletionRepository(this._remote);

  Future<DriverDeletionRequestModel?> getLatestRequest() =>
      _guard(_remote.getLatestRequest);

  Future<DriverDeletionRequestModel> requestDeletion({
    required String password,
    String? reason,
  }) => _guard(
    () => _remote.requestDeletion(password: password, reason: reason),
  );

  Future<void> cancelRequest() => _guard(_remote.cancelRequest);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
