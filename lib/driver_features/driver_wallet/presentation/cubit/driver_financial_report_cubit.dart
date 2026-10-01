import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import 'driver_financial_report_state.dart';

/// Drives the driver wallet screen's monthly financial summary —
/// `GET /api/driver/financial-report` for a given year/month.
class DriverFinancialReportCubit extends Cubit<DriverFinancialReportState> {
  final DriverWalletRepository _repository;

  DriverFinancialReportCubit(this._repository)
      : super(const DriverFinancialReportState());

  /// Which request is the latest, so a slow earlier month can never overwrite
  /// a later one.
  int _latestRequest = 0;

  Future<void> load({required int year, required int month}) async {
    if (isClosed) return;
    final request = ++_latestRequest;
    // Another month's numbers must not stay on screen under this month's
    // label while it loads; a refresh of the same month keeps its own.
    final current = state.report;
    final isOtherMonth =
        current != null && (current.year != year || current.month != month);
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearReport: isOtherMonth,
    ));
    try {
      final report = await _repository.getFinancialReport(
        year: year,
        month: month,
      );
      if (isClosed || request != _latestRequest) return;
      emit(state.copyWith(report: report, isLoading: false));
    } on DriverWalletException catch (e) {
      if (isClosed || request != _latestRequest) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }
}
