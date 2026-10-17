import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../data/models/report_month_model.dart';
import '../../data/models/report_trip_model.dart';
import '../cubit/month_report_cubit.dart';
import '../widgets/month_report_view_widget.dart';
import '../widgets/report_summary_card_widget.dart';
import '../widgets/report_trip_row_widget.dart';

/// The month's completed trips — `GET /api/driver/financial-report/trips`,
/// reached by tapping the "completed trips" card on the wallet screen. Opens
/// on the month the wallet screen shows.
class DriverTripsReportScreen extends StatelessWidget {
  final ReportMonthModel month;

  const DriverTripsReportScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<MonthReportCubit<ReportTripModel, TripsSummaryModel>>(
      create: (_) => sl<MonthReportCubit<ReportTripModel, TripsSummaryModel>>(),
      child: MonthReportViewWidget<ReportTripModel, TripsSummaryModel>(
        title: l10n.walletCompletedTrips,
        initialMonth: month,
        emptyMessage: l10n.reportTripsEmpty,
        emptyIcon: Icons.local_taxi_outlined,
        summaryBuilder: (context, summary) => ReportSummaryCardWidget(
          metrics: [
            ReportMetric.text(
              l10n.walletCompletedTrips,
              l10n.walletTripsCount('${summary.ordersCount}'),
            ),
            ReportMetric.text(
              l10n.reportTotalDistance,
              l10n.distanceKm(summary.totalDistanceKm.toStringAsFixed(1)),
            ),
            ReportMetric.amount(
              l10n.paymentTotalPaid,
              summary.ordersTotalAmount,
            ),
          ],
        ),
        itemBuilder: (context, trip) => ReportTripRowWidget(trip: trip),
      ),
    );
  }
}
