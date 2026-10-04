import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_price.dart';

/// Hero card at the top of the wallet statement: the driver's wallet
/// balance as a heavy tabular figure with its currency, what it is for, and a
/// one-line meaning. The number and the currency share one baseline and sit
/// together in the middle of the card, in either language.
class WalletStatementSummaryCardWidget extends StatelessWidget {
  final double balance;

  const WalletStatementSummaryCardWidget({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    // The number reads left to right (so a minus stays attached to it), and
    // the currency is set on its own, smaller, on the same baseline.
    final number = '${balance < 0 ? '−' : ''}${formatPrice(balance.abs())}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        l10n.paymentWalletBalance,
        formatSignedPrice(l10n, balance),
        l10n.walletBalanceHint,
      ].join('. '),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.paymentWalletBalance,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      number,
                      style: textTheme.displayLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    l10n.priceSypNewCurrency,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatOldSyp(l10n, balance),
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              l10n.walletBalanceHint,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
