import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Full-width main button (sign in, sign up, search, request…): a tall solid
/// brand-green pill with its label — text only — in the middle, and a loading
/// spinner state.
///
/// While [isLoading] the button keeps its full color so the spinner remains
/// visible; when it is disabled for any other reason ([onPressed] is null)
/// it shows in the dimmed green.
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

  @override
  Widget build(BuildContext context) {
    final enabled = isLoading || onPressed != null;
    final foreground = enabled
        ? AppColors.textOnPrimary
        : context.colors.textOnPrimaryDisabled;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: isLoading
              ? AppColors.primary
              : AppColors.primaryDisabled,
          foregroundColor: AppColors.textOnPrimary,
          disabledForegroundColor: foreground,
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
            : Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
