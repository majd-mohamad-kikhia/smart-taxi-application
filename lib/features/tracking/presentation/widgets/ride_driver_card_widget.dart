import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_vehicle_model.dart';

/// The driver header of the live trip: their photo with the rating on a
/// small badge, a verified mark by the name, and at the end the plate
/// number in its own outlined box (the way it reads on the car) with the car
/// under it. Shown once
/// `customer:ride_accepted` (or a restored `customer:active_ride`) arrives.
class RideDriverCardWidget extends StatelessWidget {
  static const double _photoSize = 60;

  final RideDriverModel driver;
  final RideVehicleModel vehicle;

  const RideDriverCardWidget({super.key, required this.driver, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final car = [vehicle.brand, vehicle.model, vehicle.color]
        .where((part) => part.trim().isNotEmpty)
        .join(' • ');
    return Row(
      children: [
        SizedBox(
          width: _photoSize,
          height: _photoSize + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              NetworkPhotoWidget(
                imagePath: driver.photoUrl,
                width: _photoSize,
                height: _photoSize,
                borderRadius: _photoSize / 2,
                placeholderIcon: Icons.person_rounded,
              ),
              if (driver.rating != null)
                Positioned(
                  bottom: 0,
                  child: _RatingBadge(rating: driver.rating!),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      driver.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Every driver who can take a ride has an approved account.
                  Tooltip(
                    message: context.l10n.driverVerified,
                    child: Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: colors.primaryContent,
                      semanticLabel: context.l10n.driverVerified,
                    ),
                  ),
                ],
              ),
              if (driver.phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.call_outlined, size: 13, color: colors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      driver.phoneNumber,
                      textDirection: TextDirection.ltr,
                      style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (vehicle.plateNumber.trim().isNotEmpty || car.isNotEmpty) ...[
          const SizedBox(width: AppConstants.paddingS),
          // The plate, and the car under it: what the customer looks for.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (vehicle.plateNumber.trim().isNotEmpty)
                  _PlateBox(plate: vehicle.plateNumber),
                if (car.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    car,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The driver's rating on a small white pill that overlaps the photo's
/// bottom edge.
class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 13),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The plate number set in an outlined box, in heavy tabular figures, read
/// left to right in any language.
class _PlateBox extends StatelessWidget {
  final String plate;

  const _PlateBox({required this.plate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: colors.textPrimary, width: 1.5),
      ),
      child: Text(
        plate,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
