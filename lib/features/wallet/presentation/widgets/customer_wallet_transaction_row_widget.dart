import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../data/models/customer_wallet_transaction_model.dart';

/// One wallet movement: what it was, its note, when, the signed amount and
/// the balance it left. Money in or out is shown by the sign, an icon and
/// the title together, never by color alone.
class CustomerWalletTransactionRowWidget extends StatelessWidget {
  final CustomerWalletTransactionModel transaction;

  const CustomerWalletTransactionRowWidget({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final amount = transaction.amount;
    final isZero = amount == 0;
    final isDebit = amount < 0;

    final amountColor = isZero
        ? colors.textSecondary
        : (isDebit ? colors.errorText : AppColors.success);
    final iconColor = isZero
        ? colors.textSecondary
        : (isDebit ? AppColors.error : AppColors.success);
    final wash = isZero
        ? colors.backgroundMuted
        : (isDebit ? colors.errorSurface : colors.successSurface);

    final title = transaction.type.label(l10n, transaction.rideId);
    final amountText = formatSignedPrice(l10n, amount, showPlus: true);
    final balanceAfter = l10n.walletBalanceAfter(
      formatSignedPrice(l10n, transaction.balanceAfter),
    );
    final createdAt = transaction.createdAt;
    final date = createdAt == null ? null : formatDateTimeValue(context, createdAt);
    final note = transaction.note;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [title, amountText, ?note, ?date, balanceAfter].join('. '),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: colors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: colors.borderLight),
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
              child: Icon(
                isDebit
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(note, style: textTheme.bodyMedium),
                  ],
                  if (date != null) ...[
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(date, style: textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    balanceAfter,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
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
