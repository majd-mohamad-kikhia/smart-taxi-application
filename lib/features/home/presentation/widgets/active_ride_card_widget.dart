import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_model.dart';

/// Summary of the ride the customer just requested — its status and
/// estimated price — shown in place of nothing while the order is live.
class ActiveRideCardWidget extends StatelessWidget {
  final RideModel ride;

  const ActiveRideCardWidget({super.key, required this.ride});

  /// Swagger's `status` enum → Arabic. Unknown values fall back to the
  /// raw value rather than an empty string.
  static const _statusLabels = {
    'requested': 'بانتظار قبول السائق',
    'accepted': 'تم قبول طلبك',
    'arrived': 'السائق وصل',
    'in_progress': 'الرحلة جارية',
    'completed': 'اكتملت الرحلة',
    'cancelled': 'تم إلغاء الطلب',
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
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  _statusLabels[ride.status] ?? ride.status,
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
                Text(
                  '${ride.price!.toStringAsFixed(0)} ل.س',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                if (ride.priceIsEstimate)
                  const Text(
                    '(سعر تقديري)',
                    style: TextStyle(
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
