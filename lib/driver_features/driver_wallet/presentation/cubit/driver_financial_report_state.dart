import 'package:equatable/equatable.dart';
import '../../data/models/driver_financial_report_model.dart';

class DriverFinancialReportState extends Equatable {
  final DriverFinancialReportModel? report;
  final bool isLoading;
  final String? errorMessage;

  const DriverFinancialReportState({
    this.report,
    this.isLoading = true,
    this.errorMessage,
  });

  DriverFinancialReportState copyWith({
    DriverFinancialReportModel? report,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearReport = false,
  }) {
    return DriverFinancialReportState(
      report: clearReport ? null : (report ?? this.report),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [report, isLoading, errorMessage];
}
