import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width destructive action button (cancel, delete, …) with a
/// loading spinner state — the error-coloured counterpart to
/// [AuthPrimaryButtonWidget].
///
/// While [isLoading] the button stays solid so the spinner stays visible, and
/// the spinner keeps the button's label as its screen-reader name; when it is
/// disabled for any other reason ([onPressed] is null) it is dimmed.
class AppDestructiveButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AppDestructiveButtonWidget({
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
          backgroundColor: AppColors.errorDark,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: isLoading
              ? AppColors.errorDark
              : AppColors.errorDark.withValues(alpha: 0.4),
          disabledForegroundColor: isLoading
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.7),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                  semanticsLabel: label,
                ),
              )
            : Text(label),
      ),
    );
  }
}
