import 'package:geolocator/geolocator.dart';

/// Whether the phone's location service (GPS) is switched on — the system
/// switch, not the app's permission — plus a way to open the settings page
/// where the driver turns it on.
class GpsStatusService {
  const GpsStatusService();

  Future<bool> isEnabled() => Geolocator.isLocationServiceEnabled();

  /// Emits `true` / `false` each time the driver switches location on or off.
  Stream<bool> statusStream() => Geolocator.getServiceStatusStream().map(
    (status) => status == ServiceStatus.enabled,
  );

  /// Opens the phone's location settings. False if the page couldn't open.
  Future<bool> openSettings() => Geolocator.openLocationSettings();
}
