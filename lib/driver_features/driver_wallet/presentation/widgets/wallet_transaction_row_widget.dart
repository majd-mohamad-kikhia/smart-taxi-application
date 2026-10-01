import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/wallet_transaction_model.dart';

class WalletTransactionRowWidget extends StatelessWidget {
  final WalletTransactionModel transaction;

  const WalletTransactionRowWidget({super.key, required this.transaction});

  bool get _isCredit => transaction.amount >= 0;

  IconData get _icon => switch (transaction.type) {
    WalletTransactionType.topup => Icons.add_circle_outline_rounded,
    WalletTransactionType.commissionDeduction => Icons.percent_rounded,
    WalletTransactionType.penalty => Icons.remove_circle_outline_rounded,
    WalletTransactionType.compensation => Icons.card_giftcard_rounded,
  };

  String get _dateLabel {
    final dt = transaction.createdAt;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} • $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _isCredit ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 20, color: amountColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.label(context.l10n),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (transaction.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _dateLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_isCredit ? '+' : ''}${context.l10n.priceSyp(transaction.amount.toStringAsFixed(2))}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
