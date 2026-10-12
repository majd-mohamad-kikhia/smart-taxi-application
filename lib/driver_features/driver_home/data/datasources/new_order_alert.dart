import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
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

/// Loops `assets/sounds/new_order.wav` for [duration] (10 s), then stops by
/// itself.
class AudioNewOrderAlert implements NewOrderAlert {
  static const duration = Duration(seconds: 10);
  static const _asset = 'sounds/new_order.wav';

  final AudioPlayer _player;
  final bool Function() _isForeground;
  Timer? _stopTimer;
  bool _sounding = false;

  /// [isForeground]: the sound plays only while the app is on screen; in the
  /// background the call notification rings instead (never both).
  AudioNewOrderAlert({AudioPlayer? player, bool Function()? isForeground})
    : _player = player ?? AudioPlayer(),
      _isForeground = isForeground ?? _appOnScreen;

  static bool _appOnScreen() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  Future<void> start({OrderOfferModel? order}) async {
    if (!_isForeground()) return;
    _restartStopTimer();
    if (_sounding) return;
    _sounding = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
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
      await _player.stop();
    } catch (e) {
      debugPrint('NewOrderAlert: could not stop the alert: $e');
    }
  }

  void _restartStopTimer() {
    _stopTimer?.cancel();
    _stopTimer = Timer(duration, stop);
  }
}
