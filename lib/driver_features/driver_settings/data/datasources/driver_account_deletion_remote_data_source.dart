import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_deletion_request_model.dart';

/// Remote data source for `/api/driver/account/deletion-request`
/// (see swagger.json).
class DriverAccountDeletionRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverAccountDeletionRemoteDataSource(this._dio, this._endpoints);

  /// The latest request, or `null` if the driver never asked.
  Future<DriverDeletionRequestModel?> getLatestRequest() async {
    final response = await _dio.get(_endpoints.driverAccountDeletionRequest);
    final request = response.data['data']['request'];
    return request == null
        ? null
        : DriverDeletionRequestModel.fromJson(request as Map<String, dynamic>);
  }

  /// Creates a pending request (201), or returns the one already pending (200).
  /// Fails with 401 for a wrong [password].
  Future<DriverDeletionRequestModel> requestDeletion({
    required String password,
    String? reason,
  }) async {
    final response = await _dio.post(
      _endpoints.driverAccountDeletionRequest,
      data: {
        'password': password,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return DriverDeletionRequestModel.fromJson(
      response.data['data']['request'] as Map<String, dynamic>,
    );
  }

  /// Cancels the pending request; 404 if nothing is pending.
  Future<void> cancelRequest() async {
    await _dio.delete(_endpoints.driverAccountDeletionRequest);
  }
}
