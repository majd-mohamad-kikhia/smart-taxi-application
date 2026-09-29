import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Outlined "Terms and conditions" button for both roles' settings
/// screens; [onPressed] opens the terms dialog.
class TermsButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const TermsButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.description_outlined, size: 20),
      label: Text(context.l10n.termsAndConditions),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
