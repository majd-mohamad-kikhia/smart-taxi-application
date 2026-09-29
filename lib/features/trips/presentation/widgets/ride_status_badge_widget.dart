import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_history_model.dart';

/// Small colored pill showing a ride's status.
class RideStatusBadgeWidget extends StatelessWidget {
  final RideStatus status;

  const RideStatusBadgeWidget({super.key, required this.status});

  Color get _color => switch (status) {
        RideStatus.completed => AppColors.success,
        RideStatus.cancelled => AppColors.error,
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label(context.l10n),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
