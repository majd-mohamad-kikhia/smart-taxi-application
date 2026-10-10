import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../localization/app_strings.dart';

class LocalNotificationService {
  /// Every notification plays the car honk: `res/raw/car_honk.wav` on
  /// Android, `Runner/car_honk.caf` (bundled in the Xcode project) on iOS.
  static const _androidSound = 'car_honk';
  static const _iosSound = 'car_honk.caf';

  /// Channel used before the honk, deleted so it doesn't linger in the
  /// system settings.
  static const _oldChannelId = 'mshoar_notifications';

  /// The quieter honk's channel, replaced by [_channel] (a louder sound and
  /// maximum importance) and deleted for the same reason.
  static const _quietHonkChannelId = 'mshoar_notifications_honk';

  /// Its id must match the `default_notification_channel_id` meta-data in
  /// `AndroidManifest.xml`. Android fixes a channel's sound when it is first
  /// created, so a new sound needs a new id.
  ///
  /// Named in the language active when it is created (Android lets the
  /// name be updated on the next launch).
  AndroidNotificationChannel get _channel => AndroidNotificationChannel(
    'mshoar_notifications_loud',
    AppStrings.current.notificationsChannelName,
    description: AppStrings.current.notificationsChannelDescription,
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound(_androidSound),
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
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.deleteNotificationChannel(channelId: _oldChannelId);
    await android?.deleteNotificationChannel(channelId: _quietHonkChannelId);
    await android?.createNotificationChannel(_channel);
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
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(_androidSound),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          sound: _iosSound,
        ),
      ),
    );
  }
}
