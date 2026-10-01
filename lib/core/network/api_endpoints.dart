/// Centralized API endpoint paths — mirrors every path documented in
/// `lib/features/auth/data/swagger.json`.
///
/// This is the ONLY place endpoint strings live. Registered in the
/// service locator as a singleton (see injection.dart) so data sources
/// receive it through constructor injection instead of reaching for
/// static globals — keeping it swappable/mockable like everything else
/// in the data layer.
class ApiEndpoints {
  const ApiEndpoints();

  // ─── Privacy policy (public) ───────────────────────────────
  String get privacyPolicy => '/api/privacy-policy';

  // ─── Contact us numbers (public) ───────────────────────────
  String get contactNumbers => '/api/contact-numbers';

  // ─── App version (public) ──────────────────────────────────
  String get appVersionCheck => '/api/app/version-check';

  // ─── Customer Auth ─────────────────────────────────────────
  String get customerSignup => '/api/customer/auth/signup';
  String get customerLogin => '/api/customer/auth/login';
  String get customerLogout => '/api/customer/auth/logout';

  // ─── Customer Profile ──────────────────────────────────────
  String get customerProfile => '/api/customer/profile';
  String get customerLanguage => '/api/customer/profile/language';

  // ─── Customer Complaints ───────────────────────────────────
  String get customerComplaints => '/api/customer/complaints';

  // ─── Customer Notifications ────────────────────────────────
  String get customerNotifications => '/api/customer/notifications';

  // ─── Customer Rides ────────────────────────────────────────
  String get customerRides => '/api/customer/rides';
  String get customerRideLocations => '/api/customer/rides/locations';
  String get customerRideChooseVehicle => '/api/customer/rides/choose-vehicle';
  String customerRideById(int id) => '/api/customer/rides/$id';
  String customerRideCancel(int id) => '/api/customer/rides/$id/cancel';

  // ─── Driver Auth ───────────────────────────────────────────
  String get driverSignup => '/api/driver/auth/signup';
  String get driverLogin => '/api/driver/auth/login';
  String get driverLogout => '/api/driver/auth/logout';
  String get driverLanguage => '/api/driver/language';

  // ─── Driver Rides ──────────────────────────────────────────
  String get driverActiveRide => '/api/driver/rides/active';
  String driverRideAccept(int id) => '/api/driver/rides/$id/accept';
  String driverRidePickup(int id) => '/api/driver/rides/$id/pickup';
  String driverRideStart(int id) => '/api/driver/rides/$id/start';
  String driverRidePause(int id) => '/api/driver/rides/$id/pause';
  String driverRideResume(int id) => '/api/driver/rides/$id/resume';
  String driverRideFinish(int id) => '/api/driver/rides/$id/finish';
  String driverRideCancel(int id) => '/api/driver/rides/$id/cancel';
  String driverRideRoute(int id) => '/api/driver/rides/$id/route';
  String driverRideConfirmPayment(int id) =>
      '/api/driver/rides/$id/confirm-payment';

  // ─── Driver Settings ───────────────────────────────────────
  String get driverSearchRadius => '/api/driver/search-radius';

  // ─── Driver Wallet ─────────────────────────────────────────
  String get driverWallet => '/api/driver/wallet';
  String get driverFinancialReport => '/api/driver/financial-report';

  // ─── Driver Complaints ─────────────────────────────────────
  String get driverComplaints => '/api/driver/complaints';

  // ─── Driver Account ────────────────────────────────────────
  /// GET latest request · POST ask for deletion · DELETE cancel the pending one.
  String get driverAccountDeletionRequest =>
      '/api/driver/account/deletion-request';

  // ─── Driver Profile ────────────────────────────────────────
  String get driverVehicle => '/api/driver/vehicle';
}
