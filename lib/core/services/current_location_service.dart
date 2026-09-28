import 'package:geolocator/geolocator.dart';

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
}
