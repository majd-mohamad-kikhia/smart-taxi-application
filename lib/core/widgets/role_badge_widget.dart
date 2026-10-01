import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../enums/user_role.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Pill showing the role picked on the role-selection screen, shown at the
/// top of any sign in / sign up screen. The whole pill is one button (48dp
/// tall, with a ripple) that takes the user back to pick another role; the
/// swap icon and "change" label say what it does, and a screen reader reads
/// both the role and the action.
class RoleBadgeWidget extends StatelessWidget {
  final UserRole role;
  final VoidCallback onChange;

  const RoleBadgeWidget({super.key, required this.role, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final roleLabel = role.label(l10n);
    const shape = StadiumBorder();

    return Semantics(
      button: true,
      label: '$roleLabel. ${l10n.change}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySurface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onChange,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role == UserRole.driver ? Icons.local_taxi_rounded : Icons.person_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(roleLabel, style: labelStyle?.copyWith(color: AppColors.primary)),
                  const SizedBox(width: AppConstants.paddingM),
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    l10n.change,
                    style: labelStyle?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
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
