import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Card telling the driver where their account-deletion request stands:
/// a title, optional body/note, and an optional action ("cancel request").
/// [isError] switches to the red look used for a declined request.
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
    final accent = isError ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorSurface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (body != null && body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: isActionLoading ? null : onAction,
                child: isActionLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLink,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
