import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../utils/format_date.dart';
import '../../data/models/app_version_model.dart';
import '../cubit/app_version_cubit.dart';
import '../widgets/app_version_blocked_layout_widget.dart';
import '../widgets/maintenance_recheck_button_widget.dart';

/// The app is under maintenance: shows the manager's message, when it should
/// be back, and a "Try again" that asks the server again and says what it
/// found. The Back button leaves the app (there is nowhere to go inside it).
class MaintenanceScreen extends StatelessWidget {
  final AppVersionModel info;

  const MaintenanceScreen({super.key, required this.info});

  /// When it is back, as a person would say it ("Today, 3:00 PM"), or — when
  /// that time has already passed — that it should be back any minute. The
  /// server sends its own time as `YYYY-MM-DD HH:mm:ss`, display only.
  String? _backAt(BuildContext context) {
    final l10n = context.l10n;
    final raw = info.maintenanceEndsAt;
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null && parsed.isBefore(DateTime.now())) {
      return l10n.appMaintenanceAnyMinute;
    }
    return l10n.appMaintenanceBackAt(formatDateTime(context, raw));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: AppVersionBlockedLayoutWidget(
            icon: Icons.build_rounded,
            title: info.title ?? l10n.appMaintenanceTitle,
            message: info.message ?? l10n.appMaintenanceMessage,
            highlight: _backAt(context),
            actions: [
              MaintenanceRecheckButtonWidget(
                onRecheck: context.read<AppVersionCubit>().recheck,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
