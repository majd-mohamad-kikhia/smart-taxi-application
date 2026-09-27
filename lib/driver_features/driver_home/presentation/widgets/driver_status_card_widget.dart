import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  driver.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(status: driver.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            driver.phone,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (vehicle != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${vehicle.brand} ${vehicle.model} • ${vehicle.color} • ${vehicle.plateNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
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

  Color get _color => switch (status) {
        DriverStatus.active => AppColors.success,
        DriverStatus.pending => AppColors.warning,
        DriverStatus.suspended => AppColors.error,
        DriverStatus.rejected => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}
