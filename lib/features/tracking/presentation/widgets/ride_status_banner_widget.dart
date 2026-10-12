import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/models/tracked_ride_model.dart';
import '../cubit/ride_tracking_state.dart';

/// Current ride status line, plus a subtle note while the socket is
/// (re)connecting or errored.
class RideStatusBannerWidget extends StatelessWidget {
  final TrackedRideModel ride;
  final RideTrackingConnectionStatus connectionStatus;

  const RideStatusBannerWidget({
    super.key,
    required this.ride,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isWaiting = ride.status == 'requested';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: isWaiting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                  )
                : const Icon(Icons.directions_car_filled_rounded, color: AppColors.textOnPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.statusLabel(context.l10n),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                ),
                if (connectionStatus != RideTrackingConnectionStatus.connected) ...[
                  const SizedBox(height: 2),
                  Text(
                    connectionStatus == RideTrackingConnectionStatus.error
                        ? context.l10n.connectionErrorRetrying
                        : context.l10n.connecting,
                    style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
