class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';
  static const String logoPath =
      'assets/icons/app_logo_icons/icon-master-1024.png';

  /// The brand slogan, the same in every language.
  static const String appSlogan = 'Smart Taxi ... Smart Life';

  /// Where every map opens until the phone's own position is known:
  /// Latakia, Syria.
  static const double defaultMapLat = 35.5317;
  static const double defaultMapLng = 35.7898;
  static const String userAgentPackage = 'com.mshoar.app';

  /// Store pages the app-update buttons fall back to when the server's
  /// version check carries no `store_url`.
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ma.smarttaxi';

  /// TODO(release): set to `https://apps.apple.com/app/id<numeric app id>`
  /// once the app has an App Store listing. Empty means "no fallback".
  static const String iosStoreUrl = '';

  /// Road-routing service for the live trip map (OSRM's `route` API). The
  /// public demo server is fine for development; point this at a
  /// self-hosted OSRM (or a compatible provider) for production traffic.
  static const String routingBaseUrl = 'https://router.project-osrm.org';

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

  static const Duration animFast = Duration(milliseconds: 200);
}
