import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/fare_breakdown_widget.dart';

/// Shown to the customer when the driver finishes the trip: how much to
/// pay the driver. It has no buttons — the tracking screen closes it when
/// the driver confirms the payment (`customer:ride_paid`).
///
/// The amount is the hero: a heavy tabular figure with a thousands
/// separator that scales down instead of wrapping. The content scrolls, so
/// the bill rows can never overflow at a large text size or in landscape.
class RidePaymentDueDialogWidget extends StatelessWidget {
  /// What the customer owes, or null when the server sent no price — the
  /// amount is then left out rather than shown as "0".
  final double? amount;

  /// Bill lines (distance, stops, waiting…), when the server sent them.
  final RideFareBreakdownModel? fare;

  const RidePaymentDueDialogWidget({super.key, this.amount, this.fare});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final amount = this.amount;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: l10n.payDriverTitle,
      child: Dialog(
        backgroundColor: AppColors.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.payments_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                l10n.payDriverTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                l10n.payDriverMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (amount != null) ...[
                const SizedBox(height: AppConstants.paddingL),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PriceTextWidget(
                    price: amount,
                    alignment: CrossAxisAlignment.center,
                    style: textTheme.displayLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
              if (fare != null) ...[
                const SizedBox(height: AppConstants.paddingL),
                FareBreakdownWidget(fare: fare!, showTotal: false),
              ],
              const SizedBox(height: AppConstants.paddingXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                      semanticsLabel: l10n.payDriverWaiting,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Flexible(
                    child: Text(
                      l10n.payDriverWaiting,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
