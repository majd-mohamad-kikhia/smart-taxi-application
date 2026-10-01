import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../data/models/app_version_model.dart';
import '../cubit/app_version_cubit.dart';
import '../widgets/app_version_blocked_layout_widget.dart';
import '../widgets/app_version_retry_button_widget.dart';

/// The app is under maintenance: shows the manager's message, when it should
/// be back, and a "Try again" that asks the server again.
class MaintenanceScreen extends StatelessWidget {
  final AppVersionModel info;

  const MaintenanceScreen({super.key, required this.info});

  /// The server sends its own time as `YYYY-MM-DD HH:mm:ss`, display only.
  String? _backAt(BuildContext context) {
    final raw = info.maintenanceEndsAt;
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final backAt = _backAt(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: AppVersionBlockedLayoutWidget(
            icon: Icons.build_rounded,
            title: info.title ?? l10n.appMaintenanceTitle,
            message: info.message ?? l10n.appMaintenanceMessage,
            details: [if (backAt != null) l10n.appMaintenanceBackAt(backAt)],
            actions: [
              AppVersionRetryButtonWidget(
                onRetry: context.read<AppVersionCubit>().check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
