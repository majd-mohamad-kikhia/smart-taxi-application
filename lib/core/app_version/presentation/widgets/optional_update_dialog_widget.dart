import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_animated_dialog.dart';
import '../../data/models/app_version_model.dart';
import '../cubit/app_version_cubit.dart';
import 'app_version_update_button_widget.dart';

/// "A new version is available" dialog over the normal flow. Only its two
/// buttons decide: "Update" opens the store, and "Later" is remembered so the
/// dialog only returns for a newer release. A stray tap on the scrim or the
/// Back button does nothing, and neither does the dialog being closed because
/// something more serious (a required update, maintenance) took over — none
/// of those is a choice, so none is remembered as "Later".
Future<void> showOptionalUpdateDialog(
  BuildContext context,
  AppVersionModel info,
) async {
  final l10n = context.l10n;
  final cubit = context.read<AppVersionCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final notes = info.releaseNotes;
  var choseLater = false;

  await showAppDialog<void>(
    context: context,
    title: info.title ?? l10n.appUpdateOptionalTitle,
    message: info.message,
    icon: Icons.system_update_rounded,
    confirmLabel: l10n.appUpdateAction,
    cancelLabel: l10n.appUpdateLater,
    barrierDismissible: false,
    content: notes == null
        ? null
        : Text(
            notes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
    onConfirm: () =>
        AppVersionUpdateButtonWidget.launch(messenger, info.storeUrl),
    onCancel: () => choseLater = true,
  );

  if (choseLater) await cubit.skipOptional(info);
}
