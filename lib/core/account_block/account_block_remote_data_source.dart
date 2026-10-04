import 'package:dio/dio.dart';
import '../models/account_block_model.dart';
import '../network/api_endpoints.dart';

class AccountBlockRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const AccountBlockRemoteDataSource(this._dio, this._endpoints);

  /// `GET /api/customer/profile/block` — may the customer order, their
  /// cancel strikes, and the block text when blocked.
  Future<AccountBlockModel> fetchCustomerBlock() async {
    final response = await _dio.get(_endpoints.customerProfileBlock);
    final data = (response.data as Map)['data'];
    final block = data is Map ? data['block'] : null;
    return block is Map
        ? AccountBlockModel.fromJson(Map<String, dynamic>.from(block))
        : AccountBlockModel.none;
  }
}
