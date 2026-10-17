import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the phone's screen on while something needs to stay in view (the
/// driver's trip). It only holds while the app is on screen: leaving the app
/// or pressing the power button lets the phone sleep as usual.
///
/// Whoever calls [keepOn] must call [allowSleep] when done. A failure here
/// must never break the screen using it, so neither call throws.
class ScreenAwakeService {
  const ScreenAwakeService();

  Future<void> keepOn() => _set(true);

  Future<void> allowSleep() => _set(false);

  Future<void> _set(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (e) {
      debugPrint('ScreenAwakeService: could not set the screen to stay on=$enabled: $e');
    }
  }
}
