import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/models/order_offer_model.dart';

/// The sound that tells the driver a new order has arrived.
abstract class NewOrderAlert {
  /// Starts the alert. If it is already sounding, keeps it going for a fresh
  /// full [duration] instead of stacking a second one. [order] is the offer
  /// that triggered it, for alerts that describe it.
  Future<void> start({OrderOfferModel? order});

  /// Silences the alert right away. Safe to call when nothing is playing.
  Future<void> stop();
}

/// Rings like an incoming call for the whole of the driver's turn on the
/// order (25 s unless the server says otherwise), then stops by itself.
/// On Android it is the phone's own ringtone at full volume, even on a
/// silent phone (see `MainActivity`); on iOS, or if that fails, it loops
/// `assets/sounds/new_order.wav` at full player volume. iOS keeps playing
/// with the app in the background (the `audio` background mode) and with the
/// silent switch on, since the sound is played as media.
class AudioNewOrderAlert implements NewOrderAlert {
  /// The driver's turn when the server doesn't say how long it is.
  static const duration = Duration(seconds: 25);
  static const _asset = 'sounds/new_order.wav';
  static const _ringtoneChannel = MethodChannel('smart_taxi/ringtone');

  final AudioPlayer _player;
  final bool Function() _isForeground;
  Timer? _stopTimer;
  bool _sounding = false;
  bool _nativeRinging = false;

  /// [isForeground]: the sound plays only while the app is on screen; in the
  /// background the call notification rings instead (never both).
  AudioNewOrderAlert({AudioPlayer? player, bool Function()? isForeground})
    : _player = player ?? AudioPlayer(),
      _isForeground = isForeground ?? _appOnScreen;

  /// How long the alert for [order] sounds: what is left of the driver's
  /// turn (the server's `expires_at`), else the turn's length, else
  /// [duration]. A turn already over by this phone's clock (a clock running
  /// ahead) falls back to the length, so the driver still hears the order.
  static Duration ringDuration(OrderOfferModel? order, {DateTime? now}) {
    final left = order?.expiresAt?.difference((now ?? DateTime.now()).toUtc());
    if (left != null && left > Duration.zero) return left;
    final seconds = order?.offerSeconds;
    if (seconds != null && seconds > 0) return Duration(seconds: seconds);
    return duration;
  }

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  static bool _appOnScreen() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  Future<void> start({OrderOfferModel? order}) async {
    // Android rings through the call notification in the background (never
    // both); iOS has no call screen, so the app itself keeps ringing.
    if (!_isIos && !_isForeground()) return;
    _restartStopTimer(ringDuration(order));
    if (_sounding) return;
    _sounding = true;
    try {
      if (await _startNativeRingtone()) return;
      await _player.setAudioContext(_audioContext);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource(_asset));
    } catch (e) {
      // A missing sound must never break receiving orders.
      _sounding = false;
      _stopTimer?.cancel();
      debugPrint('NewOrderAlert: could not play the alert: $e');
    }
  }

  @override
  Future<void> stop() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    if (!_sounding) return;
    _sounding = false;
    try {
      if (_nativeRinging) {
        _nativeRinging = false;
        await _ringtoneChannel.invokeMethod<void>('stop');
      } else {
        await _player.stop();
      }
    } catch (e) {
      debugPrint('NewOrderAlert: could not stop the alert: $e');
    }
  }

  Future<bool> _startNativeRingtone() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      _nativeRinging =
          await _ringtoneChannel.invokeMethod<bool>('start') ?? false;
    } on PlatformException catch (e) {
      debugPrint('NewOrderAlert: native ringtone failed: $e');
      _nativeRinging = false;
    } on MissingPluginException {
      _nativeRinging = false;
    }
    return _nativeRinging;
  }

  /// iOS: media playback, so the silent switch doesn't mute it and it goes
  /// on in the background. Android: the ringing usage.
  static final _audioContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.notificationRingtone,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.gainTransientExclusive,
    ),
  );

  void _restartStopTimer(Duration after) {
    _stopTimer?.cancel();
    _stopTimer = Timer(after, stop);
  }
}
