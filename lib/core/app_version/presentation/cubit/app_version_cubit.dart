import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../enums/user_role.dart';
import '../../../localization/locale_cubit.dart';
import '../../../session/session_cubit.dart';
import '../../data/models/app_version_model.dart';
import '../../data/repositories/app_version_repository.dart';
import 'app_version_state.dart';

/// App-wide answer to "may this version of the app continue?".
///
/// Singleton (see injection.dart) so the launch check, the lifecycle
/// observer, the socket listener and the blocking screens all share one
/// state. The server is asked for the *customer* app until a driver is
/// signed in — one binary serves both roles — and asked again whenever that
/// changes.
class AppVersionCubit extends Cubit<AppVersionState> {
  final AppVersionRepository _repository;
  final LocaleCubit _locale;
  final SessionCubit _session;
  late final StreamSubscription<Object?> _sessionSubscription;

  static const Duration _requestTimeout = Duration(seconds: 6);
  static const Duration _resumeRecheck = Duration(minutes: 5);
  static const int _maxSocketJitterMs = 3000;

  final Random _random = Random();
  Timer? _socketTimer;
  AppVersionApp? _checkedApp;
  DateTime? _lastCheck;
  bool _busy = false;
  bool _recheckQueued = false;

  AppVersionCubit(this._repository, this._locale, this._session)
    : super(const AppVersionChecking()) {
    _sessionSubscription = _session.stream.listen((_) {
      // A different role than the one last checked (e.g. a driver just
      // signed in) has its own versions and maintenance switch.
      if (_checkedApp != null && _checkedApp != _app) check();
    });
  }

  /// The signed-in role wins; before anyone signs in, the role picked on the
  /// role-selection screen; otherwise the customer app.
  AppVersionApp get _app =>
      (_session.state?.role ?? _chosenRole) == UserRole.driver
      ? AppVersionApp.driver
      : AppVersionApp.customer;

  UserRole? _chosenRole;

  /// The user picked [role] on the role-selection screen. A driver has their
  /// own versions and maintenance switch, so the check is asked again for
  /// them before they reach the sign-in screen.
  void onRoleChosen(UserRole role) {
    _chosenRole = role;
    if (_checkedApp != null && _checkedApp != _app) check();
  }

  /// Asks the server. [force] false is the "back from background" check: it
  /// is skipped when the last answer is less than five minutes old.
  Future<void> check({bool force = true}) async {
    if (_busy) {
      _recheckQueued = true;
      return;
    }
    final last = _lastCheck;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _resumeRecheck) {
      return;
    }

    _busy = true;
    final app = _app;
    try {
      final info = await _repository
          .check(app: app, lang: _locale.state.languageCode)
          .timeout(_requestTimeout);
      final next = await _stateFor(app, info);
      // The account changed while the request was in flight: this answer is
      // for the wrong app, the queued re-check replaces it.
      if (app != _app) {
        _recheckQueued = true;
      } else if (!isClosed) {
        _checkedApp = app;
        _lastCheck = DateTime.now();
        emit(next);
      }
    } catch (error, stackTrace) {
      // Fail open: a network/server problem must never lock users out.
      debugPrint('App version check failed: $error');
      addError(error, stackTrace);
      if (!isClosed && state is AppVersionChecking) {
        emit(const AppVersionAllowed());
      }
    } finally {
      _busy = false;
      if (_recheckQueued && !isClosed) {
        _recheckQueued = false;
        unawaited(check());
      }
    }
  }

  /// `app:version_changed` arrived: ask again after a random 0–3 s delay so
  /// thousands of phones don't hit the server in the same millisecond.
  void onServerVersionChanged() {
    _socketTimer?.cancel();
    _socketTimer = Timer(
      Duration(milliseconds: _random.nextInt(_maxSocketJitterMs)),
      check,
    );
  }

  /// "Later" on the optional dialog: don't ask again for this latest_version.
  Future<void> skipOptional(AppVersionModel info) async {
    await _repository.skip(_checkedApp ?? _app, info.latestVersion);
    // Only while still allowed: a force update or maintenance that arrived
    // while the dialog was open must not be overwritten.
    if (!isClosed && state is AppVersionAllowed) {
      emit(const AppVersionAllowed());
    }
  }

  Future<AppVersionState> _stateFor(
    AppVersionApp app,
    AppVersionModel info,
  ) async {
    switch (info.status) {
      case AppVersionStatus.maintenance:
        return AppVersionMaintenance(info);
      case AppVersionStatus.forceUpdate:
        return AppVersionForceUpdate(info);
      case AppVersionStatus.optionalUpdate:
        final skipped = await _repository.isSkipped(app, info.latestVersion);
        return skipped
            ? const AppVersionAllowed()
            : AppVersionAllowed(optional: info);
      case AppVersionStatus.ok:
        return const AppVersionAllowed();
    }
  }

  @override
  Future<void> close() {
    _socketTimer?.cancel();
    _sessionSubscription.cancel();
    return super.close();
  }
}
