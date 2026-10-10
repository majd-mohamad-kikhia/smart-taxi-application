import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import 'app_animated_dialog.dart';

/// Tells the customer or driver who just asked to delete their account that
/// the removal takes about 7 days to finish, then hands over to
/// [onContinue] — the caller's way back to the first screen (role selection).
///
/// The dialog can be left only through its button, so the explanation is
/// always read before the app leaves the settings screen.
Future<void> showAccountDeletionNoticeDialog(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  final l10n = context.l10n;
  return showAppDialog<void>(
    context: context,
    title: l10n.accountDeletionNoticeTitle,
    message: l10n.accountDeletionNoticeMessage,
    icon: Icons.schedule_rounded,
    tone: AppDialogTone.primary,
    cancelLabel: l10n.continueLabel,
    barrierDismissible: false,
    onCancel: onContinue,
  );
}
