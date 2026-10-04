import 'dart:async';
import 'package:flutter/widgets.dart';
import '../app_version/presentation/cubit/app_version_cubit.dart';
import '../app_version/presentation/cubit/app_version_state.dart';
import '../enums/user_role.dart';
import '../localization/app_strings.dart';
import '../routing/app_router.dart';
import '../session/app_user.dart';
import '../session/session_cubit.dart';
import '../widgets/app_snack_bar_widget.dart';
import 'deep_link_service.dart';

/// Decides where an office order link goes, by who is signed in:
/// - a driver: the order screen, on top of whatever is open;
/// - nobody: driver sign-in, keeping the link for after the login (the
///   sign-in screen opens it);
/// - a customer: a message — only drivers can take orders.
///
/// Works from above the [Navigator] through [AppRouter.navigatorKey]. One
/// instance per app session; [start] once the app's navigator exists.
class SharedOrderLinkHandler {
  final DeepLinkService _links;
  final SessionCubit _session;
  final AppVersionCubit _appVersion;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<AppUser?>? _sessionSubscription;

  SharedOrderLinkHandler(this._links, this._session, this._appVersion);

  Future<void> start() async {
    if (_tokenSubscription != null) return;
    _tokenSubscription = _links.sharedOrderTokens.listen(_open);
    // A link kept for a driver login is dropped if a customer signs in.
    _sessionSubscription = _session.stream.listen((user) {
      if (user?.role == UserRole.customer) _links.takePendingToken();
    });
    await _links.init();
  }

  void _open(String token) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      // Cold start: the first frame isn't built yet.
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(token));
      return;
    }
    final version = _appVersion.state;
    if (version is AppVersionForceUpdate || version is AppVersionMaintenance) {
      return;
    }
    switch (_session.state?.role) {
      case UserRole.driver:
        // One order screen at a time: a newer link replaces an open one.
        navigator.popUntil(
          (route) => route.settings.name != AppRouter.driverSharedOrder,
        );
        navigator.pushNamed(AppRouter.driverSharedOrder, arguments: token);
      case UserRole.customer:
        showAppSnackBar(
          navigator.context,
          AppStrings.current.sharedOrderDriversOnly,
          type: AppSnackBarType.warning,
        );
      case null:
        _links.keepPending(token);
        navigator.pushNamedAndRemoveUntil(
          AppRouter.driverSignIn,
          (route) => route.settings.name == AppRouter.roleSelection,
        );
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _sessionSubscription?.cancel();
  }
}
