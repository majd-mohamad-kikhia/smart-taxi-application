import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// The vehicle sheet's confirm button: a tall solid-green pill with a car icon,
/// the label ("Request {vehicle} · {price}") and an arrow in a circle at its end. A
/// `null` [onPressed] dims it.
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
          color: enabled ? AppColors.primary : AppColors.primaryDisabled,
          borderRadius: _radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: _radius,
            child: SizedBox(
              height: _height,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: foreground, size: 22),
                    const SizedBox(width: 12),
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
