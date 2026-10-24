import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection/injection.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../widgets/app_snack_bar_widget.dart';
import '../../../widgets/settings_switch_tile_widget.dart';
import '../cubit/screen_takeover_cubit.dart';
import '../cubit/screen_takeover_state.dart';

/// The driver settings' "Open the app for new orders" switch. Draws nothing
/// where the app can't open itself (iOS). Re-reads the permissions when the
/// app comes back from the system settings, so the switch never lies.
class ScreenTakeoverSwitchWidget extends StatefulWidget {
  const ScreenTakeoverSwitchWidget({super.key});

  @override
  State<ScreenTakeoverSwitchWidget> createState() =>
      _ScreenTakeoverSwitchWidgetState();
}

class _ScreenTakeoverSwitchWidgetState
    extends State<ScreenTakeoverSwitchWidget> {
  // Shared with the driver shell's permission check, so it is not closed here.
  final ScreenTakeoverCubit _cubit = sl<ScreenTakeoverCubit>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _cubit.load();
    _lifecycle = AppLifecycleListener(onResume: _cubit.load);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScreenTakeoverCubit, ScreenTakeoverState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          current.permissionDeniedCount > previous.permissionDeniedCount,
      listener: (context, state) => showAppSnackBar(
        context,
        context.l10n.screenTakeoverPermissionNeeded,
        type: AppSnackBarType.warning,
      ),
      builder: (context, state) {
        if (!state.isSupported) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SettingsSwitchTileWidget(
            icon: Icons.open_in_new_rounded,
            title: l10n.screenTakeoverTitle,
            subtitle: l10n.screenTakeoverSubtitle,
            value: state.enabled,
            onChanged: state.isRequesting ? null : _cubit.setEnabled,
          ),
        );
      },
    );
  }
}
