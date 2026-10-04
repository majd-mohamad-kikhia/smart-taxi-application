import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../data/models/driver_financial_report_model.dart';
import '../cubit/driver_financial_report_cubit.dart';
import '../cubit/driver_financial_report_state.dart';
import '../widgets/wallet_stat_card_widget.dart';
import '../widgets/wallet_statement_summary_card_widget.dart';
import 'driver_wallet_fines_screen.dart';

List<String> _monthNames(AppLocalizations l10n) => [
  l10n.monthJan,
  l10n.monthFeb,
  l10n.monthMar,
  l10n.monthApr,
  l10n.monthMay,
  l10n.monthJun,
  l10n.monthJul,
  l10n.monthAug,
  l10n.monthSep,
  l10n.monthOct,
  l10n.monthNov,
  l10n.monthDec,
];

/// The earliest month the financial-report endpoint accepts.
const int _firstYear = 2020;

/// Driver wallet tab — monthly financial statement, backed entirely by
/// `GET /api/driver/financial-report`. The fines card drills into the
/// itemized feed from `/api/driver/wallet`.
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
  int _monthOffset = 0;
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

  /// The selected (year, month): `DateTime` rolls the year over correctly in
  /// both directions.
  (int, int) get _selectedYearMonth {
    final now = DateTime.now();
    final selected = DateTime(now.year, now.month + _monthOffset);
    return (selected.year, selected.month);
  }

  bool get _canGoBack =>
      _selectedYearMonth.$1 > _firstYear ||
      (_selectedYearMonth.$1 == _firstYear && _selectedYearMonth.$2 > 1);

  String _monthLabel(AppLocalizations l10n) {
    final (year, month) = _selectedYearMonth;
    return '${_monthNames(l10n)[month - 1]} $year';
  }

  Future<void> _loadReport() {
    final (year, month) = _selectedYearMonth;
    return _reportCubit.load(year: year, month: month);
  }

  void _changeMonth(int delta) {
    setState(() => _monthOffset += delta);
    _loadReport();
  }

  void _openFines(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DriverWalletFinesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocBuilder<DriverFinancialReportCubit, DriverFinancialReportState>(
        bloc: _reportCubit,
        builder: (context, state) {
          final l10n = context.l10n;
          final report = state.report;
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.backgroundWhite,
            onRefresh: _loadReport,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingL),
              children: [
                _MonthStepper(
                  label: _monthLabel(l10n),
                  onPrevious: _canGoBack ? () => _changeMonth(-1) : null,
                  onNext: _monthOffset < 0 ? () => _changeMonth(1) : null,
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
                    onOpenFines: () => _openFines(context),
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

/// Previous / next month around the month's name. The month announces
/// itself to screen readers when it changes.
class _MonthStepper extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _MonthStepper({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Start side = previous month, end side = next month. These icons
        // mirror themselves in RTL, so the arrows point the right way in
        // both languages.
        IconButton(
          tooltip: l10n.walletPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.textSecondary,
          onPressed: onPrevious,
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.walletNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.textSecondary,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// The hero balance and the grid of the month's figures. Only the balance
/// is yellow; earnings are green, bonuses amber, fines red, and the rest
/// neutral. Every money figure carries its currency.
class _Statement extends StatelessWidget {
  final DriverFinancialReportModel report;
  final VoidCallback onOpenFines;

  const _Statement({required this.report, required this.onOpenFines});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String money(double amount) => formatSyp(l10n, amount);

    return Column(
      children: [
        WalletStatementSummaryCardWidget(balance: report.walletBalance),
        const SizedBox(height: AppConstants.paddingL),
        Row(
          children: [
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletEarnings,
                value: money(report.driverEarnings),
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.success,
                iconBackground: AppColors.successSurface,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletCompletedTrips,
                value: l10n.walletTripsCount('${report.ordersCount}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletBonuses,
                value: money(report.rewardsTotal),
                icon: Icons.card_giftcard_rounded,
                iconColor: AppColors.accent,
                iconBackground: AppColors.accentSurface,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletTotalCommissions,
                value: money(report.managerEarnings),
                icon: Icons.percent_rounded,
                iconColor: AppColors.textSecondary,
                iconBackground: AppColors.backgroundMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletFines,
                value: money(report.finesTotal),
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
                iconBackground: AppColors.errorSurface,
                onTap: onOpenFines,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: WalletStatCardWidget(
                label: l10n.walletMonthlyIncome,
                value: formatSignedPrice(l10n, report.netIncome),
              ),
            ),
          ],
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
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.textSecondary,
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
