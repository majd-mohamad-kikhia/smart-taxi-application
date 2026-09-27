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

  // ─── Health ────────────────────────────────────────────────
  String get health => '/';

  // ─── Customer Auth ─────────────────────────────────────────
  String get customerSignup => '/api/customer/auth/signup';
  String get customerLogin => '/api/customer/auth/login';
  String get customerLogout => '/api/customer/auth/logout';

  // ─── Customer Notifications ────────────────────────────────
  String get customerNotifications => '/api/customer/notifications';

  // ─── Customer Rides ────────────────────────────────────────
  String get customerRides => '/api/customer/rides';
  String customerRideById(int id) => '/api/customer/rides/$id';
  String customerRideCancel(int id) => '/api/customer/rides/$id/cancel';

  // ─── Driver Auth ───────────────────────────────────────────
  String get driverSignup => '/api/driver/auth/signup';
  String get driverLogin => '/api/driver/auth/login';
  String get driverLogout => '/api/driver/auth/logout';

  // ─── Driver Rides ──────────────────────────────────────────
  String driverRideAccept(int id) => '/api/driver/rides/$id/accept';
  String driverRidePickup(int id) => '/api/driver/rides/$id/pickup';
  String driverRideStart(int id) => '/api/driver/rides/$id/start';
  String driverRideFinish(int id) => '/api/driver/rides/$id/finish';
  String driverRideCancel(int id) => '/api/driver/rides/$id/cancel';

  // ─── Driver Settings ───────────────────────────────────────
  String get driverSearchRadius => '/api/driver/search-radius';

  // ─── Driver Wallet ─────────────────────────────────────────
  String get driverWallet => '/api/driver/wallet';

  // ─── Driver Complaints ─────────────────────────────────────
  String get driverComplaints => '/api/driver/complaints';
}
