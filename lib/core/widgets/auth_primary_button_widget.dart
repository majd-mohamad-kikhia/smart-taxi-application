import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Full-width main button (sign in, sign up, search, request…): the brand's
/// green-to-teal gradient with a soft glow, and a loading spinner state.
///
/// While [isLoading] the button keeps its full color so the spinner remains
/// visible; when it is disabled for any other reason ([onPressed] is null)
/// it shows as a dimmed gradient with no glow.
class AuthPrimaryButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButtonWidget({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final isActive = isLoading || onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isActive
              ? AppColors.primaryGradient
              : AppColors.primaryGradientDisabled,
          borderRadius: _radius,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        // The button itself is transparent: the gradient behind it is the
        // fill, and the button keeps the ripple, focus and semantics.
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            disabledBackgroundColor: AppColors.transparent,
            shadowColor: AppColors.transparent,
            foregroundColor: AppColors.textOnPrimary,
            disabledForegroundColor: isLoading
                ? AppColors.textOnPrimary
                : context.colors.textOnPrimaryDisabled,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.textOnPrimary,
                    // Keeps the button's name for screen readers while the
                    // label text is swapped for the spinner.
                    semanticsLabel: label,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
