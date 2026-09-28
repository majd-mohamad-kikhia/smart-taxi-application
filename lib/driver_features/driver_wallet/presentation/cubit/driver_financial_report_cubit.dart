import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import 'driver_financial_report_state.dart';

/// Drives the driver wallet screen's monthly financial summary —
/// `GET /api/driver/financial-report` for a given year/month.
class DriverFinancialReportCubit extends Cubit<DriverFinancialReportState> {
  final DriverWalletRepository _repository;

  DriverFinancialReportCubit(this._repository)
      : super(const DriverFinancialReportState());

  Future<void> load({required int year, required int month}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final report = await _repository.getFinancialReport(
        year: year,
        month: month,
      );
      if (isClosed) return;
      emit(state.copyWith(report: report, isLoading: false));
    } on DriverWalletException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }
}
