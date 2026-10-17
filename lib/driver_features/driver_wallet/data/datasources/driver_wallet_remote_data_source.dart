import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_financial_report_model.dart';
import '../models/month_report_page_model.dart';
import '../models/report_earning_model.dart';
import '../models/report_reward_model.dart';
import '../models/report_trip_model.dart';
import '../models/wallet_history_model.dart';
import '../models/wallet_transaction_model.dart';

/// Remote data source for the Driver Wallet feature — talks to
/// `GET /api/driver/wallet`, `GET /api/driver/financial-report` and the
/// month's detail lists under it: `/trips`, `/earnings` and `/rewards`
/// (see swagger.json).
class DriverWalletRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  /// Rows per page of the month's detail lists (the server allows 1–100).
  static const int reportPageSize = 20;

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

  Future<DriverFinancialReportModel> fetchFinancialReport({
    int? year,
    int? month,
  }) async {
    final response = await _dio.get(
      _endpoints.driverFinancialReport,
      queryParameters: {'year': ?year, 'month': ?month},
    );
    return DriverFinancialReportModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MonthReportPageModel<ReportTripModel, TripsSummaryModel>> fetchTrips({
    required int year,
    required int month,
    required int page,
  }) async {
    final data = await _fetchReportPage(
      _endpoints.driverReportTrips,
      year: year,
      month: month,
      page: page,
    );
    return MonthReportPageModel.fromJson(
      data,
      listKey: 'trips',
      summary: TripsSummaryModel.fromJson,
      item: ReportTripModel.fromJson,
    );
  }

  Future<MonthReportPageModel<ReportEarningModel, EarningsSummaryModel>>
  fetchEarnings({
    required int year,
    required int month,
    required int page,
  }) async {
    final data = await _fetchReportPage(
      _endpoints.driverReportEarnings,
      year: year,
      month: month,
      page: page,
    );
    return MonthReportPageModel.fromJson(
      data,
      listKey: 'earnings',
      summary: EarningsSummaryModel.fromJson,
      item: ReportEarningModel.fromJson,
    );
  }

  Future<MonthReportPageModel<ReportRewardModel, RewardsSummaryModel>>
  fetchRewards({
    required int year,
    required int month,
    required int page,
  }) async {
    final data = await _fetchReportPage(
      _endpoints.driverReportRewards,
      year: year,
      month: month,
      page: page,
    );
    return MonthReportPageModel.fromJson(
      data,
      listKey: 'rewards',
      summary: RewardsSummaryModel.fromJson,
      item: ReportRewardModel.fromJson,
    );
  }

  Future<Map<String, dynamic>> _fetchReportPage(
    String path, {
    required int year,
    required int month,
    required int page,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: {
        'year': year,
        'month': month,
        'page': page,
        'limit': reportPageSize,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
