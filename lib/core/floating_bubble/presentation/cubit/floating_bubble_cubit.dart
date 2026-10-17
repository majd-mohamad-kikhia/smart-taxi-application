import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/floating_bubble_overlay.dart';
import '../../data/floating_bubble_store.dart';
import 'floating_bubble_state.dart';

/// Drives the "Floating bubble" switch in the driver's settings. Turning it
/// on needs Android's "Display over other apps": the system screen is opened
/// once, and the switch only goes on if the driver allowed it. The bubble
/// itself is shown and hidden by `FloatingBubbleCoordinator`.
class FloatingBubbleCubit extends Cubit<FloatingBubbleState> {
  final FloatingBubbleOverlay _overlay;
  final FloatingBubbleStore _store;

  FloatingBubbleCubit(this._overlay, this._store)
    : super(FloatingBubbleState(isSupported: _overlay.isSupported));

  /// Reads the saved choice. A permission taken back in the system settings
  /// turns the switch off, so it never says "on" while nothing can show.
  Future<void> load() async {
    if (!state.isSupported) return;
    final stored = await _store.isEnabled();
    final enabled = stored && await _overlay.hasPermission();
    if (isClosed) return;
    emit(state.copyWith(enabled: enabled));
    if (stored && !enabled) await _store.setEnabled(false);
  }

  Future<void> setEnabled(bool value) async {
    if (!state.isSupported || state.isRequesting) return;
    if (!value) {
      emit(state.copyWith(enabled: false));
      await _store.setEnabled(false);
      await _overlay.close();
      return;
    }
    var granted = await _overlay.hasPermission();
    if (!granted) {
      emit(state.copyWith(isRequesting: true));
      await _overlay.requestPermission();
      granted = await _overlay.hasPermission();
    }
    if (isClosed) return;
    if (granted) await _store.setEnabled(true);
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
}
