import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Outlined "Privacy policy" button for both roles' settings screens;
/// [onPressed] opens the privacy policy dialog.
class PrivacyPolicyButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const PrivacyPolicyButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.privacy_tip_outlined, size: 20),
      label: Text(context.l10n.privacyPolicy),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
