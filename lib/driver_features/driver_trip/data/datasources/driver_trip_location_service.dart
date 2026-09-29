import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// The driver's own GPS feed for the in-progress map. Permission is
/// already granted by the time a ride is accepted (going online requires
/// it — see `LocationTicker`), so this only reads positions.
class DriverTripLocationService {
  static const _distanceFilterMeters = 5;
  static const _fixTimeLimit = Duration(seconds: 3);

  /// Last position the OS knows about, for an instant first pin.
  Future<Position?> lastKnownPosition() => Geolocator.getLastKnownPosition();

  /// A fresh GPS fix, or null if none arrives within a few seconds — used
  /// to pin the exact start and end of the driven distance.
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: _fixTimeLimit,
        ),
      );
    } on TimeoutException {
      debugPrint('DriverTripLocationService: no GPS fix within $_fixTimeLimit');
    } on LocationServiceDisabledException {
      debugPrint('DriverTripLocationService: location service is off');
    }
    return null;
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    ),
  );

  double distanceMeters(Position from, Position to) => Geolocator.distanceBetween(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );
}
