import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../localization/app_strings.dart';

class LocalNotificationService {
  /// Every notification plays the car honk: `res/raw/car_honk.wav` on
  /// Android, `Runner/car_honk.caf` (bundled in the Xcode project) on iOS.
  static const _androidSound = 'car_honk';
  static const _iosSound = 'car_honk.caf';

  /// The phone's own ringtone: an incoming order rings like a phone call.
  static const _ringtone = UriAndroidNotificationSound(
    'content://settings/system/ringtone',
  );

  /// The "incoming order" channel before it rang with the phone's ringtone.
  /// Android fixes a channel's sound when it is created, so it is deleted
  /// and replaced by [_callChannel] under a new id.
  static const _oldCallChannelId = 'mshoar_incoming_order';

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

  /// The "incoming order" channel: maximum importance, the phone's ringtone,
  /// and it may take over the screen like a call (see
  /// [showIncomingOrderCall]).
  AndroidNotificationChannel get _callChannel => AndroidNotificationChannel(
    'mshoar_incoming_order_call',
    AppStrings.current.incomingOrderChannelName,
    description: AppStrings.current.incomingOrderChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: _ringtone,
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
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
    await android?.deleteNotificationChannel(channelId: _oldCallChannelId);
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(_callChannel);
  }

  /// A new order while the app is not on screen: shown like an incoming call.
  /// On Android it takes over the screen (even a locked one) with a
  /// full-screen intent that opens the app (unless [fullScreenIntent] is
  /// false: then it is a heads-up notification only), rings with the phone's
  /// ringtone and vibrates until it is answered or [timeout] passes (the
  /// order's own turn). On iOS it is a time-sensitive banner: iOS gives no
  /// app a call screen without CallKit.
  Future<void> showIncomingOrderCall({
    required int id,
    required String title,
    required String body,
    String? payload,
    Duration timeout = const Duration(seconds: 10),
    bool fullScreenIntent = true,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _callChannel.id,
          _callChannel.name,
          channelDescription: _callChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: fullScreenIntent,
          ongoing: true,
          autoCancel: true,
          timeoutAfter: timeout.inMilliseconds,
          playSound: true,
          sound: _ringtone,
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 600, 300, 600, 300, 600]),
          // FLAG_INSISTENT: the sound repeats until the notification goes.
          additionalFlags: Int32List.fromList([4]),
          visibility: NotificationVisibility.public,
          ticker: title,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: _iosSound,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  /// Android 14+: whether the app may take over the screen. Asks (opens the
  /// system's setting) when it may not; true elsewhere.
  Future<bool> requestFullScreenIntentPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestFullScreenIntentPermission() ?? true;
  }

  /// Whether notifications may be shown (Android 13+ asks; true before it).
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// Android 13+: shows the system's notification permission dialog. True
  /// when allowed (also where nothing has to be asked).
  Future<bool> requestNotificationsPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
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
