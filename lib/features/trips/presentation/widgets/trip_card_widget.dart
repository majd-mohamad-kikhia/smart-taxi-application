import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/meta_item_widget.dart';
import '../../data/models/ride_history_model.dart';
import 'ride_route_widget.dart';
import 'ride_status_badge_widget.dart';

/// One past ride in the list: when it was, what it cost, and where it went.
///
/// A cancelled ride shows no price, and a ride that isn't finished shows its
/// price as an estimate. The whole card is one button for screen readers,
/// read as a single sentence.
class TripCardWidget extends StatelessWidget {
  final RideHistoryModel ride;
  final VoidCallback onTap;

  /// Shows the status pill — only useful when the list mixes statuses.
  final bool showStatus;

  const TripCardWidget({
    super.key,
    required this.ride,
    required this.onTap,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final date = ride.isScheduled && ride.scheduledAt != null
        ? l10n.rideScheduledAt(formatUtcDateTime(context, ride.scheduledAt))
        : formatDateTime(context, ride.requestedAt);
    final price = ride.shownPrice;
    final priceText = price == null ? null : formatSyp(l10n, price);
    final distance = ride.shownDistanceKm;
    final distanceText = distance == null
        ? null
        : l10n.distanceKm(distance.toStringAsFixed(1));
    final fallback = l10n.mapLocationFallback;

    final spoken = [
      if (showStatus) ride.status.label(l10n),
      date,
      ?priceText == null
          ? null
          : (ride.isPriceEstimate
                ? '$priceText ${l10n.priceEstimateTag}'
                : priceText),
      '${l10n.fromLabel}: ${ride.pickupAddress ?? fallback}',
      '${l10n.toLabel}: ${ride.dropoffAddress ?? fallback}',
      ?distanceText,
      if (ride.hasRoute) l10n.routeRecorded,
    ].join('. ');

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: spoken,
      onTap: onTap,
      child: Material(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppConstants.paddingS,
                        runSpacing: AppConstants.paddingXS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (showStatus) RideStatusBadgeWidget(status: ride.status),
                          Text(date, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (priceText != null) ...[
                      const SizedBox(width: AppConstants.paddingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PriceTextWidget(
                            price: price!,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (ride.isPriceEstimate)
                            Text(
                              l10n.priceEstimateTag,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                RideRouteWidget(
                  pickup: ride.pickupAddress,
                  dropoff: ride.dropoffAddress,
                  maxLines: 2,
                ),
                if (distanceText != null || ride.hasRoute) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  Wrap(
                    spacing: AppConstants.paddingL,
                    runSpacing: AppConstants.paddingXS,
                    children: [
                      if (distanceText != null)
                        MetaItemWidget(
                          icon: Icons.straighten_rounded,
                          label: distanceText,
                        ),
                      if (ride.hasRoute)
                        MetaItemWidget(
                          icon: Icons.map_outlined,
                          label: l10n.routeRecorded,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
