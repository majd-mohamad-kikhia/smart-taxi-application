import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Logout button + app version footer — shared by any account-holding
/// feature's settings screen (customer, driver, ...).
class LogoutFooterWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onLogout;

  const LogoutFooterWidget({
    super.key,
    required this.isLoading,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : onLogout,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.2),
              ),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.logoutFromAccount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.appTagline,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appVersionFooter(AppConstants.appVersion),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
