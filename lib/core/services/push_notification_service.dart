import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

/// Runs in a separate isolate for messages received while the app is
/// backgrounded or terminated, so it can't use the service locator.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS already displays messages carrying a `notification` block while
  // the app is in the background; only data-only messages need showing.
  if (message.notification != null) return;
  await _showMessage(LocalNotificationService(), message);
}

/// Receives Firebase Cloud Messaging pushes and displays them with
/// [LocalNotificationService].
///
/// Neither Android nor iOS displays a push on its own while the app is in
/// the foreground, so foreground messages are always shown locally.
class PushNotificationService {
  static const _tokenTimeout = Duration(seconds: 5);

  final FirebaseMessaging _messaging;
  final LocalNotificationService _localNotifications;

  PushNotificationService(this._messaging, this._localNotifications);

  Future<void> initialize() async {
    await _localNotifications.initialize();
    FirebaseMessaging.onMessage.listen(
      (message) => _showMessage(_localNotifications, message),
    );

    await _messaging.requestPermission();

    _messaging.onTokenRefresh.listen(
      (token) => debugPrint('FCM token refreshed: $token'),
    );
    debugPrint('FCM token: ${await _getToken()}');
  }

  /// The optional `fcm_token` / `platform` body fields the backend stores
  /// on customer signup, customer login and driver login. Empty when no
  /// token is available, so authentication never fails because of it.
  Future<Map<String, String>> deviceTokenFields() async {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platform == null) return const {};

    final token = await _getToken();
    if (token == null) return const {};
    return {'fcm_token': token, 'platform': platform};
  }

  Future<String?> _getToken() async {
    try {
      return await _messaging.getToken().timeout(
        _tokenTimeout,
        onTimeout: () => null,
      );
    } on FirebaseException catch (e) {
      // iOS throws here until an APNs token is available (e.g. missing
      // Push Notifications capability or an unsupported simulator).
      debugPrint('FCM token unavailable: ${e.code} ${e.message}');
      return null;
    }
  }
}

Future<void> _showMessage(
  LocalNotificationService notifications,
  RemoteMessage message,
) async {
  final title =
      message.notification?.title ?? message.data['title']?.toString();
  final body = message.notification?.body ?? message.data['body']?.toString();
  if (title == null && body == null) return;

  await notifications.show(
    id:
        (message.messageId ?? '${message.sentTime}$title').hashCode &
        0x7fffffff,
    title: title,
    body: body,
    payload: message.data.isEmpty ? null : jsonEncode(message.data),
  );
}
