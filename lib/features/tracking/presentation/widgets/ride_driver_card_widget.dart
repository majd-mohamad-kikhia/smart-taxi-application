import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_vehicle_model.dart';

/// Driver photo, name, rating and vehicle info — shown once
/// `customer:ride_accepted` (or a restored `customer:active_ride`) arrives.
class RideDriverCardWidget extends StatelessWidget {
  final RideDriverModel driver;
  final RideVehicleModel vehicle;

  const RideDriverCardWidget({super.key, required this.driver, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NetworkPhotoWidget(
          imagePath: driver.photoUrl,
          width: 56,
          height: 56,
          borderRadius: 28,
          placeholderIcon: Icons.person_rounded,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      driver.fullName,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (driver.rating != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      driver.rating!.toStringAsFixed(1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                vehicle.summary,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (driver.phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.call_outlined, size: 13, color: context.colors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      driver.phoneNumber,
                      style: TextStyle(fontSize: 12, color: context.colors.textTertiary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        NetworkPhotoWidget(
          imagePath: vehicle.photoUrl,
          width: 64,
          height: 44,
          borderRadius: 10,
          placeholderIcon: Icons.directions_car_rounded,
        ),
      ],
    );
  }
}
