import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_history_model.dart';

/// A ride's status as an icon and a word on the status's wash, so it never
/// depends on color alone. The label stays in the primary text color (the
/// icon carries the status color), which keeps it readable on every wash.
class RideStatusBadgeWidget extends StatelessWidget {
  final RideStatus status;

  const RideStatusBadgeWidget({super.key, required this.status});

  Color get _color => switch (status) {
        RideStatus.completed => AppColors.success,
        RideStatus.cancelled => AppColors.error,
        _ => AppColors.accent,
      };

  Color get _wash => switch (status) {
        RideStatus.completed => AppColors.successSurface,
        RideStatus.cancelled => AppColors.errorSurface,
        _ => AppColors.accentSurface,
      };

  IconData get _icon => switch (status) {
        RideStatus.scheduled => Icons.event_rounded,
        RideStatus.requested => Icons.schedule_rounded,
        RideStatus.accepted => Icons.directions_car_rounded,
        RideStatus.arrived => Icons.place_rounded,
        RideStatus.inProgress => Icons.route_rounded,
        RideStatus.completed => Icons.check_circle_rounded,
        RideStatus.cancelled => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: _wash,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: AppConstants.paddingXS),
          Flexible(
            child: Text(
              status.label(context.l10n),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
