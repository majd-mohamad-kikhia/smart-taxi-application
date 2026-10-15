import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/report_month_model.dart';
import '../../data/models/report_reward_model.dart';
import '../cubit/month_report_cubit.dart';
import '../widgets/month_report_view_widget.dart';
import '../widgets/report_reward_row_widget.dart';
import '../widgets/report_summary_card_widget.dart';

/// The rewards given in the month —
/// `GET /api/driver/financial-report/rewards`, reached by tapping the
/// "bonuses" card on the wallet screen. Opens on the month the wallet screen
/// shows.
class DriverRewardsReportScreen extends StatelessWidget {
  final ReportMonthModel month;

  const DriverRewardsReportScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<
      MonthReportCubit<ReportRewardModel, RewardsSummaryModel>
    >(
      create: (_) =>
          sl<MonthReportCubit<ReportRewardModel, RewardsSummaryModel>>(),
      child: MonthReportViewWidget<ReportRewardModel, RewardsSummaryModel>(
        title: l10n.walletBonuses,
        initialMonth: month,
        emptyMessage: l10n.reportRewardsEmpty,
        emptyIcon: Icons.card_giftcard_rounded,
        summaryBuilder: (context, summary) => ReportSummaryCardWidget(
          metrics: [
            ReportMetric.amount(
              l10n.walletBonuses,
              summary.rewardsTotal,
              emphasized: true,
              color: AppColors.warning,
            ),
            ReportMetric.text(
              l10n.reportRewardsCount,
              '${summary.rewardsCount}',
            ),
          ],
        ),
        itemBuilder: (context, reward) => ReportRewardRowWidget(reward: reward),
      ),
    );
  }
}
