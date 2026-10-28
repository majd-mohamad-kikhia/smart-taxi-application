import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../../../core/widgets/price_text_widget.dart';

/// The wallet's balance as the hero of the wallet screen, with a line saying
/// what the money can be used for.
class CustomerWalletBalanceWidget extends StatelessWidget {
  final double balance;

  const CustomerWalletBalanceWidget({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return Semantics(
      container: true,
      child: AppSurfaceCardWidget(
        color: colors.primarySurface,
        bordered: false,
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          children: [
            Text(
              l10n.walletBalanceTitle,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primaryContent,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: PriceTextWidget(
                price: balance,
                alignment: CrossAxisAlignment.center,
                style: textTheme.displayMedium?.copyWith(
                  color: colors.primaryContent,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              l10n.walletOnlyForRides,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
