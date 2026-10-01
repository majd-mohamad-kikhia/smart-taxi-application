import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Outlined "Contact us" button for both roles' settings screens;
/// [onPressed] opens the Contact us screen.
class ContactUsButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const ContactUsButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.support_agent_rounded, size: 20),
      label: Text(context.l10n.contactUs),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
