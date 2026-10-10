import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// A headline figure on the profile (rating, wallet balance): an icon, the
/// value as a heavy tabular figure that scales down rather than wrapping,
/// and its label. Read as one sentence by a screen reader.
class ProfileFigureTileWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// Makes the whole tile a button (e.g. the rating opens "My ratings").
  final VoidCallback? onTap;

  const ProfileFigureTileWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $value',
      button: onTap != null,
      onTap: onTap,
      child: Material(
        color: AppColors.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(height: AppConstants.paddingS),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
