import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/gps_status_cubit.dart';
import '../cubit/gps_status_state.dart';
import 'gps_required_dialog_widget.dart';

/// Wraps a driver screen so it can't be used while the phone's GPS is off.
///
/// While location is off, [child] is dimmed and can't be touched, the back
/// button does nothing, and a dialog asks the driver to switch GPS on. The
/// moment it is on again — including when the driver returns from the
/// settings page — the dialog disappears; switching it off again brings it
/// back. Drawn over the screen (not as a pushed route), so it also covers
/// a screen the app opens by itself.
class DriverGpsGuardWidget extends StatefulWidget {
  final Widget child;

  const DriverGpsGuardWidget({super.key, required this.child});

  @override
  State<DriverGpsGuardWidget> createState() => _DriverGpsGuardWidgetState();
}

class _DriverGpsGuardWidgetState extends State<DriverGpsGuardWidget>
    with WidgetsBindingObserver {
  late final GpsStatusCubit _cubit = sl<GpsStatusCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the settings page (or from the background): read the
    // switch again in case the change happened while the app wasn't looking.
    if (state == AppLifecycleState.resumed) _cubit.recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GpsStatusCubit, GpsStatusState>(
      bloc: _cubit,
      buildWhen: (previous, current) =>
          previous.isDisabled != current.isDisabled,
      builder: (context, state) {
        final isBlocked = state.isDisabled;
        return PopScope(
          canPop: !isBlocked,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: isBlocked,
                child: ExcludeSemantics(
                  excluding: isBlocked,
                  child: widget.child,
                ),
              ),
              if (isBlocked) ...[
                ModalBarrier(
                  dismissible: false,
                  color: AppColors.scrimStrong,
                  semanticsLabel: context.l10n.gpsRequiredTitle,
                ),
                GpsRequiredDialogWidget(onOpenSettings: _cubit.openSettings),
              ],
            ],
          ),
        );
      },
    );
  }
}
