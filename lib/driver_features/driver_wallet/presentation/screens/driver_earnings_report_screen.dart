import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/report_earning_model.dart';
import '../../data/models/report_month_model.dart';
import '../cubit/month_report_cubit.dart';
import '../widgets/month_report_view_widget.dart';
import '../widgets/report_earning_row_widget.dart';
import '../widgets/report_summary_card_widget.dart';

/// The money of each trip of the month —
/// `GET /api/driver/financial-report/earnings`, reached by tapping the "trip
/// earnings" card on the wallet screen. Opens on the month the wallet screen
/// shows.
class DriverEarningsReportScreen extends StatelessWidget {
  final ReportMonthModel month;

  const DriverEarningsReportScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<
      MonthReportCubit<ReportEarningModel, EarningsSummaryModel>
    >(
      create: (_) =>
          sl<MonthReportCubit<ReportEarningModel, EarningsSummaryModel>>(),
      child: MonthReportViewWidget<ReportEarningModel, EarningsSummaryModel>(
        title: l10n.walletEarnings,
        initialMonth: month,
        emptyMessage: l10n.reportEarningsEmpty,
        emptyIcon: Icons.trending_up_rounded,
        summaryBuilder: (context, summary) {
          final rate = summary.avgCommissionRate;
          return ReportSummaryCardWidget(
            metrics: [
              ReportMetric.amount(
                l10n.walletEarnings,
                summary.driverEarnings,
                emphasized: true,
                color: AppColors.success,
              ),
              ReportMetric.amount(
                l10n.paymentTotalPaid,
                summary.ordersTotalAmount,
              ),
              ReportMetric.amount(
                l10n.walletTotalCommissions,
                summary.managerEarnings,
              ),
              if (rate != null)
                ReportMetric.text(
                  l10n.reportAvgCommission,
                  l10n.reportAvgCommissionValue(
                    rate == rate.roundToDouble()
                        ? rate.toStringAsFixed(0)
                        : rate.toStringAsFixed(1),
                  ),
                ),
              ReportMetric.text(
                l10n.walletCompletedTrips,
                l10n.walletTripsCount('${summary.ordersCount}'),
              ),
            ],
          );
        },
        itemBuilder: (context, earning) =>
            ReportEarningRowWidget(earning: earning),
      ),
    );
  }
}
