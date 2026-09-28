import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width destructive action button (cancel, delete, …) with a
/// loading spinner state — the error-coloured counterpart to
/// [AuthPrimaryButtonWidget].
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
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
