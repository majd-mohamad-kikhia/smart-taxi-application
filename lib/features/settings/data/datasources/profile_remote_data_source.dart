import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/customer_profile_model.dart';

/// Remote data source for `/api/customer/profile` (see swagger.json).
class ProfileRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const ProfileRemoteDataSource(this._dio, this._endpoints);

  Future<CustomerProfileModel> getProfile() async {
    final response = await _dio.get(_endpoints.customerProfile);
    return CustomerProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Partial update — only the keys in [fields] are sent.
  Future<CustomerProfileModel> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    final response = await _dio.put(_endpoints.customerProfile, data: fields);
    return CustomerProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
