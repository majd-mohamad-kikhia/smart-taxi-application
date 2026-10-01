import 'package:flutter/material.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../data/models/app_version_model.dart';
import '../widgets/app_version_blocked_layout_widget.dart';
import '../widgets/app_version_update_button_widget.dart';

/// This version is too old to run: the only way forward is the store.
/// No back button, no way into the app.
class ForceUpdateScreen extends StatelessWidget {
  final AppVersionModel info;

  const ForceUpdateScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: AppVersionBlockedLayoutWidget(
            icon: Icons.system_update_rounded,
            title: info.title ?? l10n.appUpdateRequiredTitle,
            message: info.message ?? l10n.appUpdateRequiredMessage,
            details: [if (info.releaseNotes != null) info.releaseNotes!],
            actions: [AppVersionUpdateButtonWidget(storeUrl: info.storeUrl)],
          ),
        ),
      ),
    );
  }
}
