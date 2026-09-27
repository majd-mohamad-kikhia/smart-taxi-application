import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/wallet_history_model.dart';
import '../models/wallet_transaction_model.dart';

/// Remote data source for the Driver Wallet feature — talks to
/// `GET /api/driver/wallet` (see swagger.json).
class DriverWalletRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverWalletRemoteDataSource(this._dio, this._endpoints);

  Future<WalletHistoryModel> fetchWalletHistory({
    int page = 1,
    int limit = 10,
    WalletTransactionType? transactionType,
  }) async {
    final response = await _dio.get(
      _endpoints.driverWallet,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (transactionType != null) 'transaction_type': transactionType.toApi,
      },
    );
    return WalletHistoryModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
