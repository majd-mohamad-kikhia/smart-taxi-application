import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The sound that tells the driver a new order has arrived.
abstract class NewOrderAlert {
  /// Starts the alert. If it is already sounding, keeps it going for a fresh
  /// full [duration] instead of stacking a second one.
  Future<void> start();

  /// Silences the alert right away. Safe to call when nothing is playing.
  Future<void> stop();
}

/// Loops `assets/sounds/new_order.wav` for [duration] (10 s), then stops by
/// itself.
class AudioNewOrderAlert implements NewOrderAlert {
  static const duration = Duration(seconds: 10);
  static const _asset = 'sounds/new_order.wav';

  final AudioPlayer _player;
  Timer? _stopTimer;
  bool _sounding = false;

  AudioNewOrderAlert({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  @override
  Future<void> start() async {
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
