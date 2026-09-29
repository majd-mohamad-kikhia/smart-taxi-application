import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/tracked_ride_model.dart';

/// Pickup/dropoff addresses + distance/ETA/price row.
class RideTripSummaryWidget extends StatelessWidget {
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;
  final TrackedRideModel ride;

  const RideTripSummaryWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.backgroundMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _LocationRow(icon: Icons.radio_button_checked_rounded, color: AppColors.success, label: pickup.displayLabel),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 9),
            child: SizedBox(height: 16, child: VerticalDivider(width: 1, thickness: 1.5, color: AppColors.border)),
          ),
          _LocationRow(icon: Icons.location_on_rounded, color: AppColors.error, label: dropoff.displayLabel),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              if (ride.distanceKm != null) ...[
                const Icon(Icons.route_outlined, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(context.l10n.distanceKm(ride.distanceKm!.toStringAsFixed(1)), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
              ],
              if (ride.estimatedDurationMin != null) ...[
                const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(context.l10n.durationMinutesShort('${ride.estimatedDurationMin}'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
              const Spacer(),
              if (ride.price != null)
                Text(
                  ride.priceIsEstimate
                      ? '~${context.l10n.priceLyd(ride.price!.toStringAsFixed(2))}'
                      : context.l10n.priceLyd(ride.price!.toStringAsFixed(2)),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LocationRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
