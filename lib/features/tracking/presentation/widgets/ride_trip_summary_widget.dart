import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon_tile_widget.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../data/models/tracked_ride_model.dart';

/// Where the trip goes and what it costs: the pickup and the destination in
/// one tinted block, each with its icon tile, a small label and the address
/// in bold; then the distance, the time and the price under it.
class RideTripSummaryWidget extends StatelessWidget {
  static const double _tileSize = 36;

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
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCardWidget(
          color: colors.backgroundMuted,
          bordered: false,
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            children: [
              _LocationRow(
                icon: Icons.trip_origin_rounded,
                color: colors.primaryContent,
                label: l10n.fromLabel,
                address: pickup.displayLabel,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: _tileSize / 2 - 1),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    height: 14,
                    child: VerticalDivider(width: 2, thickness: 2, color: colors.border),
                  ),
                ),
              ),
              _LocationRow(
                icon: Icons.location_on_rounded,
                color: colors.accentContent,
                label: l10n.toLabel,
                address: dropoff.displayLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: AppConstants.paddingS,
                runSpacing: AppConstants.paddingXS,
                children: [
                  if (ride.distanceKm != null)
                    _MetaPill(
                      icon: Icons.route_outlined,
                      label: l10n.distanceKm(ride.distanceKm!.toStringAsFixed(1)),
                    ),
                  if (ride.estimatedDurationMin != null)
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: l10n.durationMinutesShort('${ride.estimatedDurationMin}'),
                    ),
                ],
              ),
            ),
            if (ride.price != null) ...[
              const SizedBox(width: AppConstants.paddingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceTextWidget(
                    price: ride.price!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (ride.priceIsEstimate)
                    Text(
                      l10n.priceEstimateTag,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A small muted pill with an icon and a figure ("4.2 km", "12 min").
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.backgroundMuted,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primaryContent),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One end of the trip: its icon tile, a small label ("From" / "To") and the
/// address in bold.
class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        AppIconTileWidget(
          icon: icon,
          size: RideTripSummaryWidget._tileSize,
          background: colors.backgroundWhite,
          foreground: color,
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textTertiary,
                ),
              ),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
