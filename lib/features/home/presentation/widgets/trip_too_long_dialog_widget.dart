import 'package:flutter/material.dart';
import '../../../../core/contact_us/data/models/contact_number_model.dart';
import '../../../../core/contact_us/presentation/widgets/contact_numbers_list_widget.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_animated_dialog.dart';

/// Tells the customer their trip is outside what the app takes orders for
/// (longer than `AppConstants.maxOrderDistanceKm`) and lists the WhatsApp
/// numbers to order through instead. The numbers are the manager's
/// customer-app contacts; each opens WhatsApp on tap.
Future<void> showTripTooLongDialog(BuildContext context) {
  final l10n = context.l10n;
  return showAppDialog<void>(
    context: context,
    title: l10n.tripTooLongTitle,
    message: l10n.tripTooLongMessage,
    icon: Icons.add_road_rounded,
    tone: AppDialogTone.warning,
    cancelLabel: l10n.gotIt,
    // The message already says what the numbers are for.
    content: const ContactNumbersListWidget(
      app: ContactUsApp.customer,
      onlyType: ContactType.whatsapp,
      showHeading: false,
    ),
  );
}
