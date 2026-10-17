import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../data/models/driver_financial_report_model.dart';
import '../../data/models/report_month_model.dart';
import '../cubit/driver_financial_report_cubit.dart';
import '../cubit/driver_financial_report_state.dart';
import '../widgets/wallet_month_stepper_widget.dart';
import '../widgets/wallet_stat_card_widget.dart';
import '../widgets/wallet_statement_summary_card_widget.dart';
import 'driver_earnings_report_screen.dart';
import 'driver_rewards_report_screen.dart';
import 'driver_trips_report_screen.dart';
import 'driver_wallet_fines_screen.dart';

/// Driver wallet tab — monthly financial statement, backed entirely by
/// `GET /api/driver/financial-report`. The fines card drills into the
/// itemized feed from `/api/driver/wallet`; the trips, earnings and bonuses
/// cards open the month's lists under `/api/driver/financial-report/`.
///
/// While a month loads there is a loader, never zeros; another month's
/// numbers never stay on screen under this month's label; and a failure
/// says so with a Retry.
class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  ReportMonthModel _month = ReportMonthModel.current();
  late final DriverFinancialReportCubit _reportCubit;

  @override
  void initState() {
    super.initState();
    _reportCubit = sl<DriverFinancialReportCubit>();
    _loadReport();
  }

  @override
  void dispose() {
    _reportCubit.close();
    super.dispose();
  }

  Future<void> _loadReport() =>
      _reportCubit.load(year: _month.year, month: _month.month);

  void _changeMonth(ReportMonthModel month) {
    setState(() => _month = month);
    _loadReport();
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocBuilder<DriverFinancialReportCubit, DriverFinancialReportState>(
        bloc: _reportCubit,
        builder: (context, state) {
          final report = state.report;
          return RefreshIndicator(
            color: context.colors.primaryContent,
            backgroundColor: context.colors.backgroundWhite,
            onRefresh: _loadReport,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppConstants.paddingL,
                AppConstants.paddingL,
                AppConstants.paddingL,
                AppConstants.paddingL + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                WalletMonthStepperWidget(
                  month: _month,
                  onChanged: _changeMonth,
                ),
                const SizedBox(height: AppConstants.paddingS),
                if (report == null && state.errorMessage != null)
                  _WalletError(
                    message: state.errorMessage!,
                    onRetry: _loadReport,
                  )
                else if (report == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingXXL * 2,
                    ),
                    child: AppLoaderWidget(),
                  )
                else ...[
                  // A refresh that failed keeps the numbers and says so.
                  if (state.errorMessage != null) ...[
                    AuthErrorBannerWidget(message: state.errorMessage!),
                    const SizedBox(height: AppConstants.paddingM),
                  ],
                  _Statement(
                    report: report,
                    onOpenTrips: () =>
                        _open(context, DriverTripsReportScreen(month: _month)),
                    onOpenEarnings: () => _open(
                      context,
                      DriverEarningsReportScreen(month: _month),
                    ),
                    onOpenRewards: () => _open(
                      context,
                      DriverRewardsReportScreen(month: _month),
                    ),
                    onOpenFines: () =>
                        _open(context, const DriverWalletFinesScreen()),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The hero balance and the month's figures, one card per row (two on wide
/// screens) so each figure is large enough to read at a glance. Only the
/// balance is solid green; earnings are green, bonuses amber, fines red, and
/// the rest neutral. Every figure shows new pounds, with old pounds under it.
/// The trips, earnings, bonuses and fines cards open their lists.
class _Statement extends StatelessWidget {
  /// Wide enough for two columns of cards.
  static const double _twoColumnsFrom = 600;

  final DriverFinancialReportModel report;
  final VoidCallback onOpenTrips;
  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenFines;

  const _Statement({
    required this.report,
    required this.onOpenTrips,
    required this.onOpenEarnings,
    required this.onOpenRewards,
    required this.onOpenFines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final cards = [
      WalletStatCardWidget(
        label: l10n.walletEarnings,
        value: formatNewSyp(l10n, report.driverEarnings),
        subValue: formatOldSyp(l10n, report.driverEarnings),
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.success,
        iconBackground: colors.successSurface,
        onTap: onOpenEarnings,
      ),
      WalletStatCardWidget(
        label: l10n.walletCompletedTrips,
        value: l10n.walletTripsCount('${report.ordersCount}'),
        icon: Icons.local_taxi_rounded,
        iconColor: colors.primaryContent,
        iconBackground: colors.primarySurface,
        onTap: onOpenTrips,
      ),
      WalletStatCardWidget(
        label: l10n.walletBonuses,
        value: formatNewSyp(l10n, report.rewardsTotal),
        subValue: formatOldSyp(l10n, report.rewardsTotal),
        icon: Icons.card_giftcard_rounded,
        iconColor: AppColors.warning,
        iconBackground: colors.warningSurface,
        onTap: onOpenRewards,
      ),
      WalletStatCardWidget(
        label: l10n.walletTotalCommissions,
        value: formatNewSyp(l10n, report.managerEarnings),
        subValue: formatOldSyp(l10n, report.managerEarnings),
        icon: Icons.percent_rounded,
        iconColor: colors.textSecondary,
        iconBackground: colors.backgroundMuted,
      ),
      WalletStatCardWidget(
        label: l10n.walletFines,
        value: formatNewSyp(l10n, report.finesTotal),
        subValue: formatOldSyp(l10n, report.finesTotal),
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.error,
        iconBackground: colors.errorSurface,
        onTap: onOpenFines,
      ),
      WalletStatCardWidget(
        label: l10n.walletMonthlyIncome,
        value: formatNewSyp(l10n, report.netIncome),
        subValue: formatOldSyp(l10n, report.netIncome),
        icon: Icons.payments_rounded,
        iconColor: colors.textSecondary,
        iconBackground: colors.backgroundMuted,
      ),
    ];

    return Column(
      children: [
        WalletStatementSummaryCardWidget(balance: report.walletBalance),
        const SizedBox(height: AppConstants.paddingL),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= _twoColumnsFrom ? 2 : 1;
            return Column(
              children: [
                for (var i = 0; i < cards.length; i += columns) ...[
                  if (i > 0) const SizedBox(height: AppConstants.paddingM),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var c = 0; c < columns; c++) ...[
                          if (c > 0)
                            const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: i + c < cards.length
                                ? cards[i + c]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WalletError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WalletError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXXL),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
