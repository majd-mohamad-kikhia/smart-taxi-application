import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/customer_wallet_page_model.dart';

/// Remote data source for `GET /api/customer/wallet`.
class CustomerWalletRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const CustomerWalletRemoteDataSource(this._dio, this._endpoints);

  /// The balance and a page of the history, newest first.
  Future<CustomerWalletPageModel> fetchWallet({
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      _endpoints.customerWallet,
      queryParameters: {'page': page, 'limit': limit},
    );
    return CustomerWalletPageModel.fromJson(
      Map<String, dynamic>.from((response.data as Map)['data'] as Map),
    );
  }
}
