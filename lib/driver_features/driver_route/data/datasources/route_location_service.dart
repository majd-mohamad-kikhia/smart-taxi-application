import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// The GPS feed behind the driver's private route tab. On-device only: it
/// reads positions and measures distances, nothing more.
class RouteLocationService {
  static const _distanceFilterMeters = 5;
  static const _fixTimeLimit = Duration(seconds: 3);

  /// Makes sure the location service is on and the app may use it,
  /// asking for permission when needed. False when the route can't be
  /// recorded.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Last position the OS knows about, for an instant first pin. Null when
  /// there is none or location isn't available.
  Future<Position?> lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('RouteLocationService: no last known position: $e');
      return null;
    }
  }

  /// A fresh GPS fix, or null if none arrives within a few seconds.
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: _fixTimeLimit,
        ),
      );
    } on TimeoutException {
      debugPrint('RouteLocationService: no GPS fix within $_fixTimeLimit');
    } on LocationServiceDisabledException {
      debugPrint('RouteLocationService: location service is off');
    }
    return null;
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    ),
  );

  double distanceMeters(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) => Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
}
