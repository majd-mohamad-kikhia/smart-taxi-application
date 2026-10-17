import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The floating bubble's platform side: a round app icon drawn over other
/// apps by native code (`FloatingBubble.kt`), reached through the
/// `smart_taxi/bubble` channel. The bubble handles its own dragging and, when
/// tapped, brings the app back and removes itself. Android only; everywhere
/// else it does nothing.
///
/// A bubble failure must never break the app, so no call here throws.
class FloatingBubbleOverlay {
  static const _channel = MethodChannel('smart_taxi/bubble');

  const FloatingBubbleOverlay();

  /// Only Android can draw over other apps.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Whether "Display over other apps" is allowed.
  Future<bool> hasPermission() => _ask('canDraw');

  /// Opens the system's "Display over other apps" screen for this app; true
  /// once the driver is back and has allowed it.
  Future<bool> requestPermission() => _ask('requestPermission');

  /// Puts the bubble on screen; false when it could not be shown.
  Future<bool> show() => _ask('show');

  Future<void> close() async {
    await _ask('hide');
  }

  Future<bool> _ask(String method) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('FloatingBubbleOverlay: $method failed: $e');
      return false;
    }
  }
}
