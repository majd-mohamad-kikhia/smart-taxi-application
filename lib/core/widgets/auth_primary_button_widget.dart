import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width submit button shared by sign in / sign up, with a loading
/// spinner state.
///
/// While [isLoading] the button stays fully yellow so the spinner remains
/// visible; when it is disabled for any other reason ([onPressed] is null)
/// it shows as a dimmed yellow.
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor:
              isLoading ? AppColors.primary : AppColors.primaryDisabled,
          disabledForegroundColor:
              isLoading ? AppColors.textOnPrimary : AppColors.textOnPrimaryDisabled,
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
    );
  }
}
