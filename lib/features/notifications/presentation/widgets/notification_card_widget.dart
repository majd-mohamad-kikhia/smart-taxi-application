import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';

class NotificationCardWidget extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCardWidget({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeIconWidget(type: notification.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatSentAt(context.l10n, notification.sentAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Time only for today's notifications, otherwise date + time.
  String _formatSentAt(AppLocalizations l10n, DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? l10n.timePm : l10n.timeAm;
    final minute = dt.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute $period';

    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return time;
    }
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}/$month/$day  $time';
  }
}

class _TypeIconWidget extends StatelessWidget {
  final NotificationType type;

  const _TypeIconWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    final isRide = type == NotificationType.ride;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isRide ? AppColors.primarySurface : AppColors.backgroundMuted,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isRide ? Icons.directions_car_rounded : Icons.info_rounded,
        color: isRide ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
