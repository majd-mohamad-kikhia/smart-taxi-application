import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_wallet_remote_data_source.dart';
import '../models/driver_financial_report_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../models/wallet_history_model.dart';
import '../models/wallet_transaction_model.dart';

/// Structured failure thrown by [DriverWalletRepository], so the Cubit
/// never has to interpret a raw exception.
class DriverWalletException implements Exception {
  final String message;

  const DriverWalletException(this.message);

  @override
  String toString() => message;
}

/// Repository for the Driver Wallet feature. The Cubit talks to this,
/// never to [DriverWalletRemoteDataSource] directly.
class DriverWalletRepository {
  final DriverWalletRemoteDataSource _remoteDataSource;

  const DriverWalletRepository(this._remoteDataSource);

  Future<WalletHistoryModel> getWalletHistory({
    int page = 1,
    WalletTransactionType? transactionType,
  }) async {
    try {
      return await _remoteDataSource.fetchWalletHistory(
        page: page,
        transactionType: transactionType,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw DriverWalletException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }

  Future<DriverFinancialReportModel> getFinancialReport({
    int? year,
    int? month,
  }) async {
    try {
      return await _remoteDataSource.fetchFinancialReport(
        year: year,
        month: month,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw DriverWalletException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
