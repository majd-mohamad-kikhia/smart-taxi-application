import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Outlined "send a report" button shown at the bottom of both roles'
/// settings screens.
class ComplaintButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const ComplaintButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.report_gmailerrorred_rounded, size: 20),
      label: Text(context.l10n.complaintSend),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
