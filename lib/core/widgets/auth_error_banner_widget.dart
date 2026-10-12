import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Inline error message shown above a form's submit button. The message is
/// primary-colored body text (readable on the red wash); red is kept for
/// the icon and border. It is a live region, so screen readers announce it
/// as soon as it appears after a failed submit.
class AuthErrorBannerWidget extends StatelessWidget {
  final String message;

  const AuthErrorBannerWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: context.colors.errorSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.colors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
