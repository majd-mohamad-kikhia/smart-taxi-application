import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import 'app_animated_dialog.dart';

/// Tells a driver the server refused to accept an order because the wallet
/// is too low. [message] is the server's own text — already in the driver's
/// language — shown exactly as it came; nothing here is hardcoded, since
/// both the wording and the limit behind it can change on the server.
///
/// A dialog rather than a passing toast: the driver has to act (top up)
/// before any order can be accepted. The order itself stays on screen —
/// nothing was accepted, and it is still open to others.
Future<void> showWalletTooLowDialog(BuildContext context, String message) {
  return showAppDialog<void>(
    context: context,
    title: message,
    icon: Icons.account_balance_wallet_rounded,
    tone: AppDialogTone.warning,
    cancelLabel: context.l10n.gotIt,
  );
}
