import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Card telling the driver where their account-deletion request stands:
/// a title, optional body/note, and an optional action ("cancel request").
/// [isError] switches to the red look used for a declined request; a request
/// still under review is amber (not yellow, which stays for the one primary
/// action). The card is a live region, so a change of status is announced.
class DriverDeletionStatusCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final bool isError;
  final String? actionLabel;
  final bool isActionLoading;
  final VoidCallback? onAction;

  const DriverDeletionStatusCardWidget({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.isError = false,
    this.actionLabel,
    this.isActionLoading = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isError ? AppColors.error : AppColors.accent;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: isError ? AppColors.errorSurface : AppColors.accentSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(body!, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppConstants.paddingS),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: isActionLoading ? null : onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textLink,
                    minimumSize: const Size(48, 48),
                  ),
                  child: isActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          actionLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
