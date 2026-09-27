import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../enums/user_role.dart';
import '../theme/app_colors.dart';

/// Small chip showing the role picked on the role-selection screen, with
/// a "change" action, shown at the top of any sign in / sign up screen.
class RoleBadgeWidget extends StatelessWidget {
  final UserRole role;
  final VoidCallback onChange;

  const RoleBadgeWidget({super.key, required this.role, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role == UserRole.driver ? Icons.local_taxi_rounded : Icons.person_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onChange,
            child: Text(
              'تغيير',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
