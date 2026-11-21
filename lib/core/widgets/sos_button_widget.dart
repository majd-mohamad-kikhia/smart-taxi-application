import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';
import '../utils/open_external_url.dart';
import 'app_snack_bar_widget.dart';

/// The emergency button of a trip in progress, for the driver and the
/// customer: one tap opens the phone's dialer on the emergency line
/// ([AppConstants.sosPhoneNumber]), with nothing to confirm in between. Says
/// so when the device can't place calls.
class SosButtonWidget extends StatelessWidget {
  const SosButtonWidget({super.key});

  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.callNotAvailable;
    final opened = await openExternalUrl('tel:${AppConstants.sosPhoneNumber}');
    if (!opened) {
      showAppSnackBarOn(messenger, failure, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.sosButtonHint,
      excludeSemantics: true,
      child: Material(
        color: AppColors.errorDark,
        shape: const StadiumBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _call(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emergency_rounded, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.sosButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
