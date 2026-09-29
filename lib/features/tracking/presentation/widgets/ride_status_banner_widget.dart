import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          if (isWaiting)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.statusLabel(context.l10n),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (connectionStatus != RideTrackingConnectionStatus.connected) ...[
                  const SizedBox(height: 2),
                  Text(
                    connectionStatus == RideTrackingConnectionStatus.error
                        ? context.l10n.connectionErrorRetrying
                        : context.l10n.connecting,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
