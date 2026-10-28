import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/customer_wallet_remote_data_source.dart';
import '../models/customer_wallet_page_model.dart';

/// Repository for the customer's wallet. Failures surface as
/// [ApiException] so the Cubit never sees a raw `DioException`.
class CustomerWalletRepository {
  static const int pageSize = 20;

  final CustomerWalletRemoteDataSource _remote;

  const CustomerWalletRepository(this._remote);

  Future<CustomerWalletPageModel> getPage(int page) async {
    try {
      return await _remote.fetchWallet(page: page, limit: pageSize);
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
