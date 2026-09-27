import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/wallet_transaction_model.dart';
import 'driver_wallet_fines_screen.dart';
import '../cubit/driver_wallet_cubit.dart';
import '../cubit/driver_wallet_state.dart';
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

// The backend has no monthly-statement endpoint yet, so every figure
// below except the wallet balance, the fines count (both real, from
// /api/driver/wallet) and the fines drill-down is a placeholder pending
// that API.
const _mockPreviousBalance = -148251.0;
const _mockTotalCommissions = 28560.0;
const _mockPreviousCompanyPayments = 0.0;
const _mockCompensations = 0.0;
const _mockCompletedTrips = 11;
const _mockMonthlyIncome = 408000.0;

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

/// Driver wallet tab — monthly financial statement. Only the fines card
/// is functional (drills into the real `/api/driver/wallet` fines feed);
/// the rest is a read-only summary pending a dedicated statement API.
class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  int _monthOffset = 0;
  late final DriverWalletCubit _walletCubit;
  late final DriverWalletCubit _finesCubit;

  @override
  void initState() {
    super.initState();
    _walletCubit = sl<DriverWalletCubit>(param1: null)..initialize();
    _finesCubit = sl<DriverWalletCubit>(param1: WalletTransactionType.penalty)
      ..initialize();
  }

  @override
  void dispose() {
    _walletCubit.close();
    _finesCubit.close();
    super.dispose();
  }

  String get _monthLabel {
    final now = DateTime.now();
    final total = now.month - 1 + _monthOffset;
    final year = now.year + total ~/ 12;
    final month = total % 12;
    return '${_arabicMonths[month]} $year';
  }

  void _openFines(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DriverWalletFinesScreen()));
  }

  Future<void> _refresh() {
    return Future.wait([_walletCubit.refresh(), _finesCubit.refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: const Text('كشف الحساب المالي')),
      body: BlocBuilder<DriverWalletCubit, DriverWalletState>(
        bloc: _walletCubit,
        builder: (context, walletState) => RefreshIndicator(
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
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _monthOffset--),
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
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.textSecondary,
                    onPressed: _monthOffset < 0
                        ? () => setState(() => _monthOffset++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              WalletStatementSummaryCardWidget(
                amountOwed: _formatAmount(walletState.walletBalance),
                previousBalance: _formatAmount(_mockPreviousBalance),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BlocBuilder<DriverWalletCubit, DriverWalletState>(
                      bloc: _finesCubit,
                      builder: (context, finesState) => WalletStatCardWidget(
                        label: 'الغرامات الإدارية',
                        value: _formatAmount(finesState.total, suffix: ''),
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.error,
                        iconBackground: AppColors.errorSurface,
                        onTap: () => _openFines(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WalletStatCardWidget(
                      label: 'العمولات الكلية',
                      value: _formatAmount(_mockTotalCommissions, suffix: ''),
                      icon: Icons.percent_rounded,
                      iconColor: AppColors.primary,
                      iconBackground: AppColors.primarySurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WalletStatCardWidget(
                      label: 'تسديدات سابقة للشركة',
                      value: _formatAmount(
                        _mockPreviousCompanyPayments,
                        suffix: '',
                      ),
                      icon: Icons.payments_rounded,
                      iconColor: AppColors.success,
                      iconBackground: AppColors.successSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WalletStatCardWidget(
                      label: 'التعويضات المالية',
                      value: _formatAmount(_mockCompensations, suffix: ''),
                      icon: Icons.sync_alt_rounded,
                      iconColor: AppColors.accent,
                      iconBackground: AppColors.accentSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WalletStatCardWidget(
                      label: 'عدد المشاوير المكتملة',
                      value: '$_mockCompletedTrips رحلة',
                      valueColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WalletStatCardWidget(
                      label: 'إجمالي دخل الشهر',
                      value: _formatAmount(_mockMonthlyIncome),
                      valueColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
