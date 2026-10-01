import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../localization/app_strings.dart';

class LocalNotificationService {
  /// Its id must match the `default_notification_channel_id` meta-data in
  /// `AndroidManifest.xml`.
  ///
  /// Named in the language active when it is created (Android lets the
  /// name be updated on the next launch).
  AndroidNotificationChannel get _channel => AndroidNotificationChannel(
    'mshoar_notifications',
    AppStrings.current.notificationsChannelName,
    description: AppStrings.current.notificationsChannelDescription,
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
