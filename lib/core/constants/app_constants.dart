/// App-wide constants for the Mshoar app.
class AppConstants {
  AppConstants._();

  // ─── App Info ──────────────────────────────────────────────
  static const String appName = 'Smart Taxi';
  static const String appVersion = '3.4.0';
  static const String logoPath =
      'assets/icons/app_logo_icons/icon-master-1024.png';

  // ─── Map ───────────────────────────────────────────────────
  static const double defaultMapLat = 24.7136;
  static const double defaultMapLng = 46.6753;
  static const double defaultMapZoom = 14.5;
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackage = 'com.mshoar.app';

  /// Road-routing service for the live trip map (OSRM's `route` API). The
  /// public demo server is fine for development; point this at a
  /// self-hosted OSRM (or a compatible provider) for production traffic.
  static const String routingBaseUrl = 'https://router.project-osrm.org';

  // ─── UI ────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  static const double mapHeight = 220.0;
  static const double appBarHeight = 60.0;
  static const double bottomNavHeight = 64.0;

  // ─── Durations ─────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
