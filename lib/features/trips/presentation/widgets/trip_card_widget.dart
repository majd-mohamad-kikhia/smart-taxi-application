import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_history_model.dart';
import 'ride_route_widget.dart';
import 'ride_status_badge_widget.dart';

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
    return Material(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showStatus) ...[
                    RideStatusBadgeWidget(status: ride.status),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    formatRideDate(ride.requestedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRidePrice(context.l10n, ride.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RideRouteWidget(
                pickup: ride.pickupAddress,
                dropoff: ride.dropoffAddress,
              ),
              if (ride.distanceKm != null || ride.hasRoute) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (ride.distanceKm != null)
                      Text(
                        context.l10n.distanceKm(ride.distanceKm!.toStringAsFixed(1)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (ride.hasRoute) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.route_rounded,
                        size: 16,
                        color: AppColors.mapRouteDriven,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `2026-09-27 13:00:00` → `2026-09-27 13:00`.
String formatRideDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  return raw.length >= 16 ? raw.substring(0, 16) : raw;
}

String formatRidePrice(AppLocalizations l10n, double price) =>
    l10n.priceSyp(price.toStringAsFixed(2));
