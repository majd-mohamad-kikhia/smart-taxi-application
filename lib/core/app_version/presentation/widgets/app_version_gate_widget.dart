import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection/injection.dart';
import '../../../routing/app_router.dart';
import '../../../session/session_cubit.dart';
import '../cubit/app_version_cubit.dart';
import '../cubit/app_version_state.dart';
import 'optional_update_dialog_widget.dart';

/// Sits above the whole app (via `MaterialApp.builder`) so a force update,
/// maintenance or optional update can show from anywhere — splash, a trip in
/// progress, … It also re-checks when the app comes back to the foreground.
///
/// Force update / maintenance replace the whole navigation stack with a
/// screen that can't be backed out of; once the server lets the user
/// through again the stack is reset to the app's normal start.
class AppVersionGateWidget extends StatefulWidget {
  final Widget child;

  const AppVersionGateWidget({super.key, required this.child});

  @override
  State<AppVersionGateWidget> createState() => _AppVersionGateWidgetState();
}

class _AppVersionGateWidgetState extends State<AppVersionGateWidget>
    with WidgetsBindingObserver {
  /// The blocking state currently on screen, if any.
  AppVersionState? _blocking;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The launch check finished before this widget existed: `main` already
    // opened on the blocking screen, and an optional update still needs its
    // dialog once the first frame is up.
    final state = context.read<AppVersionCubit>().state;
    if (state is AppVersionForceUpdate || state is AppVersionMaintenance) {
      _blocking = state;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(context.read<AppVersionCubit>().state);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppVersionCubit>().check(force: false);
    }
  }

  void _apply(AppVersionState state) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    switch (state) {
      case AppVersionForceUpdate(:final info):
        _block(navigator, state, AppRouter.forceUpdate, info);
      case AppVersionMaintenance(:final info):
        _block(navigator, state, AppRouter.maintenance, info);
      case AppVersionAllowed(:final optional):
        if (_blocking != null) {
          // Maintenance ended / the app was updated: back into the app.
          _blocking = null;
          navigator.pushNamedAndRemoveUntil(
            AppRouter.routeForUser(sl<SessionCubit>().state),
            (_) => false,
          );
        }
        if (optional != null && !_dialogOpen) {
          final context = AppRouter.navigatorKey.currentContext;
          if (context == null) return;
          _dialogOpen = true;
          showOptionalUpdateDialog(
            context,
            optional,
          ).whenComplete(() => _dialogOpen = false);
        }
      case AppVersionChecking():
        break;
    }
  }

  void _block(
    NavigatorState navigator,
    AppVersionState state,
    String route,
    Object info,
  ) {
    if (_blocking == state) return;
    _blocking = state;
    navigator.pushNamedAndRemoveUntil(route, (_) => false, arguments: info);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppVersionCubit, AppVersionState>(
      listener: (context, state) => _apply(state),
      child: widget.child,
    );
  }
}
