import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../data/models/wallet_transaction_model.dart';

/// One wallet movement: what it was, its full reason, when, the amount with
/// its sign, and the balance it left. Money in or out is shown by a sign, an
/// icon and the type's name together, never by color alone. Which way it
/// goes comes from the type (a commission or a fine takes money out), and a
/// zero amount is shown neutral rather than as a credit.
class WalletTransactionRowWidget extends StatelessWidget {
  final WalletTransactionModel transaction;

  const WalletTransactionRowWidget({super.key, required this.transaction});

  IconData get _icon => switch (transaction.type) {
    WalletTransactionType.topup => Icons.add_circle_outline_rounded,
    WalletTransactionType.commissionDeduction => Icons.percent_rounded,
    WalletTransactionType.penalty => Icons.remove_circle_outline_rounded,
    WalletTransactionType.compensation => Icons.healing_rounded,
    WalletTransactionType.reward => Icons.card_giftcard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final magnitude = transaction.amount.abs();
    final isZero = magnitude == 0;
    final isDebit = transaction.type.isDebit;

    final amountColor = isZero
        ? AppColors.textSecondary
        : (isDebit ? AppColors.errorText : AppColors.success);
    final iconColor = isZero
        ? AppColors.textSecondary
        : (isDebit ? AppColors.error : AppColors.success);
    final wash = isZero
        ? AppColors.backgroundMuted
        : (isDebit ? AppColors.errorSurface : AppColors.successSurface);

    final amountText = formatSignedPrice(
      l10n,
      isDebit ? -magnitude : magnitude,
      showPlus: true,
    );
    final date = formatDateTimeValue(context, transaction.createdAt);
    final balanceAfter = l10n.walletBalanceAfter(
      formatSignedPrice(l10n, transaction.balanceAfter),
    );
    final description = transaction.description;
    final hasDescription = description != null && description.isNotEmpty;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        transaction.type.label(l10n),
        amountText,
        if (hasDescription) description,
        date,
        balanceAfter,
      ].join('. '),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: wash,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Icon(_icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.type.label(l10n),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: AppConstants.paddingXS),
                    // The full reason: for a fine it is the whole point.
                    Text(
                      description,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(date, style: textTheme.bodySmall),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    balanceAfter,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              amountText,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
