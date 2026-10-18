import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why [CurrentLocationService.getCurrentLocation] couldn't get a GPS fix.
///
/// Mirrors `driver_features/driver_home/data/location_ticker.dart`'s enum
/// of the same shape. Not imported from there — that file is
/// driver-feature-local and cross-feature imports are disallowed, so this
/// small pair is intentionally duplicated here as a core/global service.
enum LocationFailureReason {
  /// The device's location service (GPS) is off entirely.
  serviceDisabled,

  /// Location service is on, but the user denied (or permanently denied)
  /// this app's permission request.
  permissionDenied,
}

/// Thrown by [CurrentLocationService.getCurrentLocation] when location
/// services or the permission needed to read GPS aren't available.
class LocationPermissionDeniedException implements Exception {
  final LocationFailureReason reason;

  const LocationPermissionDeniedException(this.reason);
}

/// One-shot GPS read, used to center the map picker on the user's
/// current location after they explicitly opt in via the GPS button.
class CurrentLocationService {
  Future<Position> getCurrentLocation() async {
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

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static const _askedOnHomeKey = 'location_asked_on_home';

  /// The phone's position for the order screen's default pickup. The very
  /// first time it asks for the location permission (the customer is about
  /// to order, so it makes sense then); after that it never asks again and
  /// behaves like [getPositionIfAllowed], so a customer who said no is not
  /// nagged on every visit. Null when location is off or not granted.
  Future<Position?> getPositionAskingOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_askedOnHomeKey) ?? false)) {
        await prefs.setBool(_askedOnHomeKey, true);
        return await getCurrentLocation();
      }
    } on LocationPermissionDeniedException {
      return null;
    } on Exception {
      // A failing preferences store or GPS read only means no default.
    }
    return getPositionIfAllowed();
  }

  /// A fix this old is no longer "where the customer is".
  static const Duration _maxLastKnownAge = Duration(minutes: 15);

  /// The phone's position for a quiet purpose (ranking search results by
  /// distance), or null when it can't be had without bothering the user:
  /// location off, permission not granted (it is never asked for here), or
  /// no fix within a few seconds. Cheap — the phone's last known fix is used
  /// while it is recent, and a coarse one otherwise.
  Future<Position?> getPositionIfAllowed() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null &&
        DateTime.now().difference(lastKnown.timestamp) < _maxLastKnownAge) {
      return lastKnown;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } on TimeoutException {
      return lastKnown;
    }
  }

  /// Where the phone is right now, for a request that must not wait on it
  /// (a driver accepting a ride): a fresh fix for at most [limit], else the
  /// last known one. Null when location is off or not granted (permission
  /// is never asked for here) or nothing is known.
  Future<Position?> quickPosition({
    Duration limit = const Duration(seconds: 2),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: limit,
          ),
        );
      } on TimeoutException {
        return await Geolocator.getLastKnownPosition();
      }
    } on Exception {
      return null;
    }
  }
}
