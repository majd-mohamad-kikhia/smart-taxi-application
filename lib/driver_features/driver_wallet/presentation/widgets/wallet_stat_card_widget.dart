import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// A single labeled figure in the wallet statement. The [label] sits over
/// the [value] (large), with an optional [subValue] under it (the same
/// amount in old pounds). Pass [icon] for the round badge. Pass [onTap] to
/// make the card open something: it then shows a chevron and reads as a
/// button.
///
/// Made to take a full row, so the figures keep a comfortable reading size
/// instead of being squeezed to fit half a screen.
class WalletStatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;

  /// Defaults to the theme's primary text color.
  final Color? valueColor;
  final VoidCallback? onTap;

  const WalletStatCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final card = Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground ?? context.colors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? context.colors.primaryContent,
              ),
            ),
            const SizedBox(width: AppConstants.paddingL),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor ?? context.colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppConstants.paddingS),
            Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: context.colors.textTertiary,
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: [label, value, ?subValue].join(': '),
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
