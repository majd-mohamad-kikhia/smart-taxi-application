import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection/injection.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../widgets/app_snack_bar_widget.dart';
import '../../../widgets/settings_switch_tile_widget.dart';
import '../cubit/floating_bubble_cubit.dart';
import '../cubit/floating_bubble_state.dart';

/// The driver settings' "Floating bubble" switch. Draws nothing where the
/// bubble can't exist (iOS). Re-reads the permission when the app comes back
/// from the system settings, so the switch never lies.
class FloatingBubbleSwitchWidget extends StatefulWidget {
  const FloatingBubbleSwitchWidget({super.key});

  @override
  State<FloatingBubbleSwitchWidget> createState() =>
      _FloatingBubbleSwitchWidgetState();
}

class _FloatingBubbleSwitchWidgetState
    extends State<FloatingBubbleSwitchWidget> {
  late final FloatingBubbleCubit _cubit;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _cubit = sl<FloatingBubbleCubit>()..load();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (!_cubit.state.isRequesting) _cubit.load();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FloatingBubbleCubit, FloatingBubbleState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          current.permissionDeniedCount > previous.permissionDeniedCount,
      listener: (context, state) => showAppSnackBar(
        context,
        context.l10n.floatingBubblePermissionNeeded,
        type: AppSnackBarType.warning,
      ),
      builder: (context, state) {
        if (!state.isSupported) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SettingsSwitchTileWidget(
            icon: Icons.bubble_chart_rounded,
            title: l10n.floatingBubbleTitle,
            subtitle: l10n.floatingBubbleSubtitle,
            value: state.enabled,
            onChanged: state.isRequesting ? null : _cubit.setEnabled,
          ),
        );
      },
    );
  }
}
