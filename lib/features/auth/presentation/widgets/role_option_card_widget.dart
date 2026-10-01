import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// A selectable card representing one [UserRole] on the role-selection
/// screen. The two cards form one choice, so screen readers get each as a
/// button that is checked or not, in a mutually exclusive group.
class RoleOptionCardWidget extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleOptionCardWidget({
    super.key,
    required this.role,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.label(l10n), style: textTheme.titleMedium),
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(role.description(l10n), style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.textTertiary,
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
