import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// The vehicle sheet's confirm button: a tall solid-green pill with only its
/// label ("Request {vehicle} · {price}") in the middle. A `null` [onPressed]
/// dims it.
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
