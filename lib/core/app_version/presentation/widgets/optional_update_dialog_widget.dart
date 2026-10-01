import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_animated_dialog.dart';
import '../../data/models/app_version_model.dart';
import '../cubit/app_version_cubit.dart';
import 'app_version_update_button_widget.dart';

/// "A new version is available" dialog over the normal flow. Anything other
/// than "Update" (the "Later" button, or backing out) counts as "Later": the
/// choice is remembered so the dialog only returns for a newer release.
Future<void> showOptionalUpdateDialog(
  BuildContext context,
  AppVersionModel info,
) async {
  final l10n = context.l10n;
  final cubit = context.read<AppVersionCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final notes = info.releaseNotes;
  var updating = false;

  await showAppDialog<void>(
    context: context,
    title: info.title ?? l10n.appUpdateOptionalTitle,
    message: info.message,
    icon: Icons.system_update_rounded,
    confirmLabel: l10n.appUpdateAction,
    cancelLabel: l10n.appUpdateLater,
    content: notes == null
        ? null
        : Text(
            notes,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
    onConfirm: () {
      updating = true;
      AppVersionUpdateButtonWidget.launch(messenger, info.storeUrl);
    },
  );

  if (!updating) await cubit.skipOptional(info);
}
