import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/screen_takeover_platform.dart';
import '../../data/screen_takeover_store.dart';
import 'screen_takeover_state.dart';

/// Drives the "Open the app for new orders" switch in the driver's settings
/// and the permission check on the first launch of each app version.
///
/// One instance for the whole app: the driver shell runs the check while the
/// settings tab shows the switch, and both must see the same answer. The
/// order alert itself only reads [ScreenTakeoverStore].
class ScreenTakeoverCubit extends Cubit<ScreenTakeoverState> {
  final ScreenTakeoverPlatform _platform;
  final ScreenTakeoverStore _store;
  final Future<String> Function() _appVersion;

  ScreenTakeoverCubit(this._platform, this._store, this._appVersion)
    : super(ScreenTakeoverState(isSupported: _platform.isSupported));

  /// Reads the saved choice. A permission taken back in the system settings
  /// shows the switch off, so it never says "on" while nothing can open.
  Future<void> load() async {
    if (!state.isSupported || state.isRequesting) return;
    final stored = await _store.isEnabled();
    final enabled = stored && (await _platform.missing()).isEmpty;
    if (isClosed || state.isRequesting) return;
    emit(state.copyWith(enabled: enabled));
  }

  Future<void> setEnabled(bool value) async {
    if (!state.isSupported || state.isRequesting) return;
    if (!value) {
      emit(state.copyWith(enabled: false));
      await _store.setEnabled(false);
      return;
    }
    emit(state.copyWith(isRequesting: true));
    final granted = await _platform.requestMissing();
    await _store.setEnabled(granted);
    if (isClosed) return;
    emit(
      state.copyWith(
        enabled: granted,
        isRequesting: false,
        permissionDeniedCount: granted
            ? state.permissionDeniedCount
            : state.permissionDeniedCount + 1,
      ),
    );
  }

  /// The first launch of a new app version (or install): when the switch is
  /// on, asks for whatever it still needs, so an update that adds a
  /// permission asks for it right away. Asks once per version; when the
  /// driver refuses, the switch goes off and can be turned on again.
  Future<void> checkAfterUpdate() async {
    if (!state.isSupported || state.isRequesting) return;
    if (!await _store.isEnabled()) return;
    final version = await _appVersion();
    if (await _store.checkedVersion() == version) return;
    // Remembered before asking, so a closed app is not asked again.
    await _store.setCheckedVersion(version);
    if ((await _platform.missing()).isEmpty) {
      await load();
      return;
    }
    emit(state.copyWith(isRequesting: true));
    final granted = await _platform.requestMissing();
    await _store.setEnabled(granted);
    if (isClosed) return;
    emit(state.copyWith(enabled: granted, isRequesting: false));
  }
}
