import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';

/// Card showing the signed-in driver's identity, status badge and
/// (if registered) their vehicle summary.
class DriverStatusCardWidget extends StatelessWidget {
  final DriverUserModel driver;

  const DriverStatusCardWidget({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final vehicle = driver.vehicle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  driver.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(status: driver.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            driver.phone,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
          if (vehicle != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.directions_car_rounded, color: context.colors.primaryContent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${vehicle.brand} ${vehicle.model} • ${vehicle.color} • ${vehicle.plateNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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

class _StatusBadge extends StatelessWidget {
  final DriverStatus status;

  const _StatusBadge({required this.status});

  Color _color(BuildContext context) => switch (status) {
        DriverStatus.active => context.colors.primaryContent,
        DriverStatus.pending => AppColors.warning,
        DriverStatus.suspended => AppColors.error,
        DriverStatus.rejected => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        status.label(context.l10n),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
