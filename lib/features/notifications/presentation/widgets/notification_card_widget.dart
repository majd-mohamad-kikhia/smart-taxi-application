import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_date.dart';
import '../../data/models/notification_model.dart';

/// One notification. An unread one is on the yellow wash with a bold title
/// and a "New" label with a dot, so it never relies on color alone. The whole
/// card is one button (it marks the notification read and, when it is about
/// a trip, opens it) read as a single sentence.
class NotificationCardWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;
    final date = formatDateTimeValue(context, notification.sentAt);
    final hasMessage = notification.message.isNotEmpty;

    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: [
        if (isUnread) l10n.notificationNew,
        notification.title,
        if (hasMessage) notification.message,
        date,
      ].join('. '),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primarySurface : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        // The ink lives on a Material above the fill, so the ripple shows.
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeIconWidget(type: notification.type),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        if (hasMessage) ...[
                          const SizedBox(height: AppConstants.paddingXS),
                          Text(
                            notification.message,
                            style: textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ],
                        const SizedBox(height: AppConstants.paddingS),
                        Wrap(
                          spacing: AppConstants.paddingM,
                          runSpacing: AppConstants.paddingXS,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(date, style: textTheme.bodySmall),
                            if (isUnread)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingXS),
                                  Text(
                                    l10n.notificationNew,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
