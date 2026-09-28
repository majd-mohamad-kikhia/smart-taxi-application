import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows system notifications through flutter_local_notifications.
class LocalNotificationService {
  /// Its id must match the `default_notification_channel_id` meta-data in
  /// `AndroidManifest.xml`.
  static const _channel = AndroidNotificationChannel(
    'mshoar_notifications',
    'الإشعارات',
    description: 'تحديثات الرحلات والعروض والتنبيهات',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  /// Safe to call more than once; later calls reuse the first one.
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested once through FirebaseMessaging instead,
        // so the user isn't prompted twice.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
