import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import 'app_neutral_button_widget.dart';

/// Logout button + app version footer — shared by any account-holding
/// feature's settings screen (customer, driver, ...).
///
/// Logging out is reversible, so the button is neutral; red is kept for the
/// permanent "delete my account" action shown beneath it.
class LogoutFooterWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onLogout;

  /// Shown right under the logout button, above the tagline and version —
  /// e.g. the "delete my account" block (customer button, driver request status).
  final Widget? belowLogout;

  const LogoutFooterWidget({
    super.key,
    required this.isLoading,
    this.onLogout,
    this.belowLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppNeutralButtonWidget(
            label: l10n.logoutFromAccount,
            icon: Icons.logout_rounded,
            isLoading: isLoading,
            onPressed: onLogout,
          ),
        ),
        if (belowLogout != null) ...[
          // A clear gap, so the permanent action isn't one slip below logout.
          const SizedBox(height: AppConstants.paddingXXL),
          belowLogout!,
        ],
        const SizedBox(height: AppConstants.paddingL),
        Text(l10n.appTagline, textAlign: TextAlign.center, style: textTheme.bodySmall),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          l10n.appVersionFooter(AppConstants.appVersion),
          textAlign: TextAlign.center,
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}
