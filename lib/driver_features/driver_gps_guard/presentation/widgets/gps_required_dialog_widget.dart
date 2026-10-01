import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_dialog_layout_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';

/// The dialog that asks the driver to switch the phone's location (GPS) on.
/// It has no close button: it goes away only when location is on again.
///
/// Built on the app's branded dialog, so it looks and moves like every other
/// one, and in the warning (amber) tone: switching GPS on is something the
/// driver can fix in a moment, not an error. It is named and announced as a
/// dialog, so a screen reader moves to it as soon as it appears.
class GpsRequiredDialogWidget extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const GpsRequiredDialogWidget({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      liveRegion: true,
      explicitChildNodes: true,
      label: l10n.gpsRequiredTitle,
      child: AppDialogLayoutWidget(
        child: AppAnimatedDialog(
          title: l10n.gpsRequiredTitle,
          message: l10n.gpsRequiredMessage,
          cancelLabel: l10n.goBack,
          icon: Icons.location_off_rounded,
          tone: AppDialogTone.warning,
          showActions: false,
          content: AuthPrimaryButtonWidget(
            label: l10n.gpsOpenSettings,
            isLoading: false,
            onPressed: onOpenSettings,
          ),
        ),
      ),
    );
  }
}
