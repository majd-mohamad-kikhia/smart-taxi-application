import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/price_text_widget.dart';

/// Summary of the ride the customer just requested — its status and
/// estimated price — shown in place of nothing while the order is live.
class ActiveRideCardWidget extends StatelessWidget {
  final RideModel ride;

  const ActiveRideCardWidget({super.key, required this.ride});

  /// Swagger's `status` enum → localized label. Unknown values fall back
  /// to the raw value rather than an empty string.
  String _statusLabel(AppLocalizations l10n) => switch (ride.status) {
    'requested' => l10n.rideAwaitingDriver,
    'accepted' => l10n.rideAwaitingArrival,
    'arrived' => l10n.rideDriverArrived,
    'in_progress' => l10n.rideInProgress,
    'completed' => l10n.rideCompleted,
    'cancelled' => l10n.rideRequestCancelled,
    _ => ride.status,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIndicator(status: ride.status, label: _statusLabel(context.l10n)),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  _statusLabel(context.l10n),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '#${ride.id}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (ride.price != null) ...[
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                PriceTextWidget(
                  price: ride.price!,
                  alignment: CrossAxisAlignment.start,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                if (ride.priceIsEstimate)
                  Text(
                    context.l10n.priceEstimateTag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A spinner only while the request still waits for a driver; every other
/// status gets an icon that says where the ride stands.
class _StatusIndicator extends StatelessWidget {
  final String status;
  final String label;

  const _StatusIndicator({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    if (status == 'requested') {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
          semanticsLabel: label,
        ),
      );
    }
    final icon = switch (status) {
      'completed' => Icons.check_circle_rounded,
      'cancelled' => Icons.cancel_rounded,
      'in_progress' => Icons.route_rounded,
      _ => Icons.local_taxi_rounded,
    };
    return Icon(icon, size: 18, color: AppColors.primary);
  }
}
