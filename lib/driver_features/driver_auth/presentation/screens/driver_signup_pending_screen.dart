import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';

/// Shown after a driver's signup: the account exists but waits for a
/// manager's approval, so there is nothing to open yet. The only way on is
/// back to sign in.
class DriverSignupPendingScreen extends StatelessWidget {
  const DriverSignupPendingScreen({super.key});

  void _toSignIn(BuildContext context) => Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRouter.driverSignIn, (route) => false);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingXXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.primary),
                    const SizedBox(height: AppConstants.paddingXL),
                    Text(
                      l10n.driverPendingTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      l10n.driverPendingMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXXL),
                    AuthPrimaryButtonWidget(
                      label: l10n.driverPendingAction,
                      isLoading: false,
                      onPressed: () => _toSignIn(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
