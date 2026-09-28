import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import 'driver_wallet_fines_screen.dart';
import '../cubit/driver_financial_report_cubit.dart';
import '../cubit/driver_financial_report_state.dart';
import '../widgets/wallet_stat_card_widget.dart';
import '../widgets/wallet_statement_summary_card_widget.dart';

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _formatAmount(num value, {String suffix = ' ل.س'}) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${isNegative ? '-' : ''}$buffer$suffix';
}

/// Driver wallet tab — monthly financial statement, backed entirely by
/// `GET /api/driver/financial-report`. The fines card drills into the
/// itemized feed from `/api/driver/wallet`.
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

  (int, int) get _selectedYearMonth {
    final now = DateTime.now();
    final total = now.month - 1 + _monthOffset;
    final year = now.year + total ~/ 12;
    final month = total % 12 + 1;
    return (year, month);
  }

  String get _monthLabel {
    final (year, month) = _selectedYearMonth;
    return '${_arabicMonths[month - 1]} $year';
  }

  void _loadReport() {
    final (year, month) = _selectedYearMonth;
    _reportCubit.load(year: year, month: month);
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

  Future<void> _refresh() {
    final (year, month) = _selectedYearMonth;
    return _reportCubit.load(year: year, month: month);
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
          final report = state.report;
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.backgroundWhite,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppColors.textSecondary,
                      onPressed: _monthOffset < 0
                          ? () => _changeMonth(1)
                          : null,
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        _monthLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppColors.textSecondary,
                      onPressed: () => _changeMonth(-1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.errorMessage != null && report == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  )
                else ...[
                  WalletStatementSummaryCardWidget(
                    amountOwed: _formatAmount(report?.walletBalance ?? 0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: WalletStatCardWidget(
                          label: 'الغرامات الإدارية',
                          value: _formatAmount(
                            report?.finesTotal ?? 0,
                            suffix: '',
                          ),
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorSurface,
                          onTap: () => _openFines(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: WalletStatCardWidget(
                          label: 'العمولات الكلية',
                          value: _formatAmount(
                            report?.managerEarnings ?? 0,
                            suffix: '',
                          ),
                          icon: Icons.percent_rounded,
                          iconColor: AppColors.primary,
                          iconBackground: AppColors.primarySurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WalletStatCardWidget(
                    label: 'المكافآت',
                    value: _formatAmount(report?.rewardsTotal ?? 0, suffix: ''),
                    icon: Icons.card_giftcard_rounded,
                    iconColor: AppColors.accent,
                    iconBackground: AppColors.accentSurface,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: WalletStatCardWidget(
                          label: 'عدد المشاوير المكتملة',
                          value: '${report?.ordersCount ?? 0} رحلة',
                          valueColor: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: WalletStatCardWidget(
                          label: 'إجمالي دخل الشهر',
                          value: _formatAmount(report?.netIncome ?? 0),
                          valueColor: AppColors.primary,
                        ),
                      ),
                    ],
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
