import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/localization/app_strings.dart';

/// Why [LocationTicker.start] couldn't get a GPS fix.
enum LocationFailureReason {
  /// The device's location service (GPS) is off entirely — the OS
  /// never shows a permission dialog for this, only a settings toggle.
  serviceDisabled,

  /// The device's location service is on, but the driver denied (or has
  /// permanently denied) this app's permission request.
  permissionDenied,
}

/// Thrown by [LocationTicker.start] when location services or the
/// permission needed to read GPS aren't available.
class LocationPermissionDeniedException implements Exception {
  final LocationFailureReason reason;

  const LocationPermissionDeniedException(this.reason);
}

/// Owns GPS permission + throttled position updates for the driver's
/// live-location socket emit.
///
/// Geolocator's own `distanceFilter` covers "emit on movement", and the
/// periodic heartbeat covers "emit every few seconds even while
/// stationary" — together matching the backend's suggested throttle
/// (emit on whichever of time/distance happens first) without flooding
/// the socket on every raw GPS tick.
class LocationTicker {
  static const _distanceFilterMeters = 25;
  static const _heartbeatInterval = Duration(seconds: 4);

  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeat;
  Position? _lastPosition;
  void Function(Position position)? _onPosition;

  /// Bumped on every [start]/[stop] so a slow first fix from an earlier run
  /// can't report after it was stopped.
  int _run = 0;

  Future<void> start(void Function(Position position) onPosition) async {
    // A retry after a failed attempt must not stack a second subscription
    // (and heartbeat) on top of the one still running.
    await stop();
    await _ensurePermission();

    final run = ++_run;
    _onPosition = onPosition;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(
      (position) {
        _lastPosition = position;
        onPosition(position);
      },
      onError: (Object error) => debugPrint('LocationTicker: position stream error: $error'),
    );

    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      final position = _lastPosition;
      if (position != null) onPosition(position);
    });

    unawaited(_seedFirstFix(run));
  }

  /// Sends the latest known position again right now. Called when the socket
  /// (re)connects: fixes that arrived before it existed were dropped, and the
  /// server only lists the driver as available once it has a location.
  void resend() {
    final position = _lastPosition;
    if (position != null) _onPosition?.call(position);
  }

  /// The position stream can take a while to deliver its first fix (and with
  /// a distance filter, only delivers on movement), so ask for one directly:
  /// the last known one at once, then a fresh one.
  Future<void> _seedFirstFix(int run) async {
    try {
      final known = await Geolocator.getLastKnownPosition();
      if (known != null && run == _run && _lastPosition == null) {
        _lastPosition = known;
        _onPosition?.call(known);
      }
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (run != _run) return;
      _lastPosition = current;
      _onPosition?.call(current);
    } catch (e) {
      debugPrint('LocationTicker: could not get a first fix: $e');
    }
  }

  Future<void> stop() async {
    _run++;
    await _positionSub?.cancel();
    _positionSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastPosition = null;
    _onPosition = null;
  }

  /// Android keeps the stream (and with it the process, and so the
  /// socket) alive while backgrounded only as a foreground service, and
  /// iOS only with the `location` background mode — otherwise the OS
  /// suspends the app, Socket.IO stops answering pings and the server
  /// drops the driver off the live map.
  LocationSettings _locationSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMeters,
          intervalDuration: _heartbeatInterval,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: AppStrings.current.locationSharingTitle,
            notificationText: AppStrings.current.locationSharingText,
            notificationChannelName: AppStrings.current.locationSharingChannel,
            enableWakeLock: true,
            enableWifiLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMeters,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMeters,
        );
    }
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationPermissionDeniedException(
        LocationFailureReason.serviceDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
        LocationFailureReason.permissionDenied,
      );
    }
  }
}
