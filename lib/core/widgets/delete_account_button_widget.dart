import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Quiet destructive "delete my account" button at the bottom of the
/// settings screens (customer and driver).
class DeleteAccountButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteAccountButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      label: Text(context.l10n.deleteAccount),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.errorText,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
