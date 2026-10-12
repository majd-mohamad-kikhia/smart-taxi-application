import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// The vehicle sheet's confirm button: a tall pill in the brand's gradient
/// with the label ("Request {vehicle} · {price}") and an arrow in a circle at
/// its end, and a soft glow. A `null` [onPressed] dims it and takes the glow
/// away. Only the label and its enabled state change between builds, so the
/// gradient and shadow are cheap to repaint.
class VehicleRequestButtonWidget extends StatelessWidget {
  static const _height = 60.0;
  static const _radius = BorderRadius.all(Radius.circular(_height / 2));

  final String label;
  final VoidCallback? onPressed;

  const VehicleRequestButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled
        ? AppColors.textOnPrimary
        : context.colors.textOnPrimaryDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? AppColors.primaryGradient
              : AppColors.primaryGradientDisabled,
          borderRadius: _radius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: _radius,
            child: SizedBox(
              height: _height,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 24, end: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(
                          alpha: enabled ? 0.22 : 0.12,
                        ),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: foreground,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
