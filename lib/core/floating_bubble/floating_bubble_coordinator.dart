import 'package:flutter/widgets.dart';
import 'data/floating_bubble_overlay.dart';
import 'data/floating_bubble_store.dart';

/// Decides when the floating bubble is on screen: while the app is in the
/// background and the driver (signed in: the driver shell feeds this the app
/// lifecycle and logout stops it) turned the bubble on and allowed "Display
/// over other apps". Online or not. It goes away when the app is opened
/// again and on logout; a tap on it also brings the app back (natively).
class FloatingBubbleCoordinator {
  final FloatingBubbleOverlay _overlay;
  final FloatingBubbleStore _store;

  /// The app is in the background, so the bubble may be showing.
  bool _inBackground = false;
  bool _showing = false;

  FloatingBubbleCoordinator(this._overlay, this._store);

  /// Hides the bubble (logout, shell closed).
  Future<void> stop() async {
    _inBackground = false;
    await _hide();
  }

  Future<void> onLifecycleChanged(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _inBackground = true;
        await _showIfAllowed();
      case AppLifecycleState.resumed:
        _inBackground = false;
        await _hide();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _showIfAllowed() async {
    if (_showing) return;
    if (!await _store.isEnabled() || !await _overlay.hasPermission()) return;
    // The driver may have come back while we checked.
    if (!_inBackground || _showing) return;
    _showing = true;
    await _overlay.show();
  }

  /// Also called when the bubble already removed itself (a tap): closing a
  /// bubble that is not there is harmless.
  Future<void> _hide() async {
    if (!_showing) return;
    _showing = false;
    await _overlay.close();
  }
}
