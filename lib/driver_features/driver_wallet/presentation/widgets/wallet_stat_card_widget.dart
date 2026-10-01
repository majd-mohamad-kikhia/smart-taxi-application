import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// A single labeled value tile in the wallet statement grid. Money values
/// are tabular and scale down instead of wrapping. Pass [icon] for the round
/// badge. Pass [onTap] to make the tile open something: it then shows a
/// chevron and reads as a button.
class WalletStatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final Color valueColor;
  final VoidCallback? onTap;

  const WalletStatCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.valueColor = AppColors.textPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final card = Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor,
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
          if (icon != null) ...[
            const SizedBox(width: AppConstants.paddingS),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: AppConstants.paddingXS),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: '$label: $value',
      onTap: onTap,
      child: onTap == null
          ? card
          : Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                onTap: onTap,
                child: card,
              ),
            ),
    );
  }
}
