import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../floating_bubble/data/floating_bubble_overlay.dart';
import '../../services/local_notification_service.dart';

/// What Android must allow for a new order to open the app by itself.
enum TakeoverPermission {
  /// Shows the order's notification (Android 13+ asks).
  notifications,

  /// Lets that notification take over the screen like a call (Android 14+
  /// asks, in the system settings).
  fullScreenIntent,

  /// "Display over other apps": lets the app come to the front while the
  /// phone is unlocked and another app is on screen.
  overlay,
}

/// The platform side of "open the app for new orders": the permissions it
/// needs and bringing the app to the front. Android only; everywhere else
/// nothing is missing and nothing happens.
///
/// A failure here must never break receiving orders, so no call throws.
class ScreenTakeoverPlatform {
  static const _channel = MethodChannel('smart_taxi/takeover');

  final LocalNotificationService _notifications;
  final FloatingBubbleOverlay _overlay;

  ScreenTakeoverPlatform(this._notifications, this._overlay);

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// The permissions not allowed yet, in the order they are asked for.
  Future<List<TakeoverPermission>> missing() async {
    if (!isSupported) return const [];
    return [
      for (final permission in TakeoverPermission.values)
        if (!await _isGranted(permission)) permission,
    ];
  }

  /// Asks for every missing permission, one after the other (the system
  /// shows one screen at a time). True when all are allowed in the end.
  Future<bool> requestMissing() async {
    for (final permission in await missing()) {
      try {
        await _request(permission);
      } catch (e) {
        debugPrint('ScreenTakeoverPlatform: $permission request failed: $e');
      }
    }
    return (await missing()).isEmpty;
  }

  /// Puts the running app in front of whatever is on screen. The system
  /// lets it through only with "Display over other apps" allowed.
  Future<void> bringToFront() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('bringToFront');
    } catch (e) {
      debugPrint('ScreenTakeoverPlatform: bringToFront failed: $e');
    }
  }

  Future<bool> _isGranted(TakeoverPermission permission) async {
    try {
      return switch (permission) {
        TakeoverPermission.notifications =>
          await _notifications.areNotificationsEnabled(),
        TakeoverPermission.fullScreenIntent =>
          await _channel.invokeMethod<bool>('canFullScreenIntent') ?? true,
        TakeoverPermission.overlay => await _overlay.hasPermission(),
      };
    } catch (e) {
      debugPrint('ScreenTakeoverPlatform: $permission check failed: $e');
      // Unknown counts as allowed, so a broken check never nags the driver.
      return true;
    }
  }

  Future<void> _request(TakeoverPermission permission) async {
    switch (permission) {
      case TakeoverPermission.notifications:
        await _notifications.requestNotificationsPermission();
      case TakeoverPermission.fullScreenIntent:
        await _notifications.requestFullScreenIntentPermission();
      case TakeoverPermission.overlay:
        await _overlay.requestPermission();
    }
  }
}
