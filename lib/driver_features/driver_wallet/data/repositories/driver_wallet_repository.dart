import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_wallet_remote_data_source.dart';
import '../models/driver_financial_report_model.dart';
import '../models/month_report_page_model.dart';
import '../models/report_earning_model.dart';
import '../models/report_reward_model.dart';
import '../models/report_trip_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../models/wallet_history_model.dart';
import '../models/wallet_transaction_model.dart';

class DriverWalletException implements Exception {
  final String message;

  const DriverWalletException(this.message);

  @override
  String toString() => message;
}

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
        error is ApiException
            ? error.message
            : AppStrings.current.errServerUnreachable,
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
        error is ApiException
            ? error.message
            : AppStrings.current.errServerUnreachable,
      );
    }
  }

  /// One page of the month's completed trips.
  Future<MonthReportPageModel<ReportTripModel, TripsSummaryModel>> getTrips({
    required int year,
    required int month,
    required int page,
  }) => _guard(
    () => _remoteDataSource.fetchTrips(year: year, month: month, page: page),
  );

  /// One page of the money split of the month's trips.
  Future<MonthReportPageModel<ReportEarningModel, EarningsSummaryModel>>
  getEarnings({required int year, required int month, required int page}) =>
      _guard(
        () => _remoteDataSource.fetchEarnings(
          year: year,
          month: month,
          page: page,
        ),
      );

  /// One page of the rewards given in the month.
  Future<MonthReportPageModel<ReportRewardModel, RewardsSummaryModel>>
  getRewards({required int year, required int month, required int page}) =>
      _guard(
        () => _remoteDataSource.fetchRewards(
          year: year,
          month: month,
          page: page,
        ),
      );

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;
      throw DriverWalletException(
        error is ApiException
            ? error.message
            : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
