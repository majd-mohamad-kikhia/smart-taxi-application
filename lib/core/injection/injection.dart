import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import '../../driver_features/driver_auth/data/datasources/driver_local_data_source.dart';
import '../../driver_features/driver_auth/data/datasources/driver_remote_data_source.dart';
import '../../driver_features/driver_auth/data/repositories/driver_repository.dart';
import '../../driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../driver_features/driver_home/data/datasources/driver_socket_service.dart';
import '../../driver_features/driver_home/data/location_ticker.dart';
import '../../driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import '../../driver_features/driver_profile/data/datasources/driver_vehicle_remote_data_source.dart';
import '../../driver_features/driver_profile/data/repositories/driver_vehicle_repository.dart';
import '../../driver_features/driver_profile/presentation/cubit/driver_vehicle_cubit.dart';
import '../../driver_features/driver_settings/data/datasources/driver_complaints_remote_data_source.dart';
import '../../driver_features/driver_settings/data/repositories/driver_complaints_repository.dart';
import '../../driver_features/driver_settings/presentation/cubit/driver_complaint_cubit.dart';
import '../../driver_features/driver_settings/presentation/cubit/driver_settings_cubit.dart';
import '../../driver_features/driver_wallet/data/datasources/driver_wallet_remote_data_source.dart';
import '../../driver_features/driver_wallet/data/models/wallet_transaction_model.dart';
import '../../driver_features/driver_wallet/data/repositories/driver_wallet_repository.dart';
import '../../driver_features/driver_wallet/presentation/cubit/driver_financial_report_cubit.dart';
import '../../driver_features/driver_wallet/presentation/cubit/driver_wallet_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';
import '../enums/user_role.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_error_handler.dart';
import '../services/current_location_service.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_service.dart';
import '../session/session_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/home/data/datasources/places_remote_data_source.dart';
import '../../features/home/data/datasources/ride_request_remote_data_source.dart';
import '../../features/home/data/repositories/places_repository.dart';
import '../../features/home/data/repositories/ride_request_repository.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/tracking/presentation/cubit/tracking_cubit.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
/// Call once at app startup before [runApp].
void setupInjection() {
  // ─── Core Networking ────────────────────────────────────────
  sl.registerLazySingleton<ApiEndpoints>(() => const ApiEndpoints());
  sl.registerLazySingleton<ApiErrorHandler>(
    () => ApiErrorHandler(sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<ApiErrorHandler>()));

  // ─── Core Session ───────────────────────────────────────────
  sl.registerLazySingleton<SessionCubit>(() => SessionCubit());

  // ─── Core Services ──────────────────────────────────────────
  sl.registerLazySingleton<CurrentLocationService>(
    () => CurrentLocationService(),
  );
  sl.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(),
  );
  sl.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      FirebaseMessaging.instance,
      sl<LocalNotificationService>(),
    ),
  );

  // ─── Auth Feature ───────────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => const AuthLocalDataSource(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      sl<ApiClient>().dio,
      sl<ApiEndpoints>(),
      sl<PushNotificationService>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl<AuthRemoteDataSource>(), sl<AuthLocalDataSource>()),
  );
  // Singleton (not a factory) so the selected role and submit state
  // survive navigation across role-selection → sign in / sign up.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(sl<AuthRepository>(), sl<SessionCubit>()),
  );
  // Other features trigger logout through SessionCubit instead of
  // importing AuthCubit directly (no cross-feature imports).
  sl<SessionCubit>().registerLogoutHandler(
    UserRole.rider,
    () => sl<AuthCubit>().logout(),
  );

  // ─── Driver Features ────────────────────────────────────────
  sl.registerLazySingleton<DriverLocalDataSource>(
    () => const DriverLocalDataSource(),
  );
  sl.registerLazySingleton<DriverRemoteDataSource>(
    () => DriverRemoteDataSource(
      sl<ApiClient>().dio,
      sl<ApiEndpoints>(),
      sl<PushNotificationService>(),
    ),
  );
  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepository(sl<DriverRemoteDataSource>(), sl<DriverLocalDataSource>()),
  );
  // Singleton (not a factory) so the signed-in driver survives navigation
  // from sign in into the driver app shell.
  sl.registerLazySingleton<DriverAuthCubit>(
    () => DriverAuthCubit(sl<DriverRepository>(), sl<SessionCubit>()),
  );
  sl<SessionCubit>().registerLogoutHandler(
    UserRole.driver,
    () async {
      await sl<DriverPresenceCubit>().goOffline();
      await sl<DriverAuthCubit>().logout();
    },
  );

  // ─── Driver Home Feature ────────────────────────────────────
  sl.registerFactory<DriverSocketService>(() => DriverSocketService());
  sl.registerFactory<LocationTicker>(() => LocationTicker());
  // Singleton so the live-location connection survives tab switches in
  // `DriverMainWrapperScreen`'s `IndexedStack`.
  sl.registerLazySingleton<DriverPresenceCubit>(
    () => DriverPresenceCubit(sl<DriverSocketService>(), sl<LocationTicker>()),
  );

  // ─── Driver Settings Feature ────────────────────────────────
  sl.registerFactory<DriverSettingsCubit>(
    () => DriverSettingsCubit(sl<DriverAuthCubit>()),
  );
  sl.registerLazySingleton<DriverComplaintsRemoteDataSource>(
    () => DriverComplaintsRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<DriverComplaintsRepository>(
    () => DriverComplaintsRepository(sl<DriverComplaintsRemoteDataSource>()),
  );
  sl.registerFactory<DriverComplaintCubit>(
    () => DriverComplaintCubit(sl<DriverComplaintsRepository>()),
  );

  // ─── Driver Wallet Feature ──────────────────────────────────
  sl.registerLazySingleton<DriverWalletRemoteDataSource>(
    () => DriverWalletRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<DriverWalletRepository>(
    () => DriverWalletRepository(sl<DriverWalletRemoteDataSource>()),
  );
  // param1 optionally filters to a single transaction type (e.g. the
  // driver complaints/fines drill-down); pass null for the unfiltered feed.
  sl.registerFactoryParam<DriverWalletCubit, WalletTransactionType?, void>(
    (transactionType, _) => DriverWalletCubit(
      sl<DriverWalletRepository>(),
      transactionType: transactionType,
    ),
  );
  sl.registerFactory<DriverFinancialReportCubit>(
    () => DriverFinancialReportCubit(sl<DriverWalletRepository>()),
  );

  // ─── Driver Profile Feature ─────────────────────────────────
  sl.registerLazySingleton<DriverVehicleRemoteDataSource>(
    () => DriverVehicleRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<DriverVehicleRepository>(
    () => DriverVehicleRepository(sl<DriverVehicleRemoteDataSource>()),
  );
  sl.registerFactory<DriverVehicleCubit>(
    () => DriverVehicleCubit(sl<DriverVehicleRepository>()),
  );

  // ─── Home Feature ───────────────────────────────────────────
  sl.registerLazySingleton<RideRequestRemoteDataSource>(
    () => RideRequestRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<RideRequestRepository>(
    () => RideRequestRepository(sl<RideRequestRemoteDataSource>()),
  );
  sl.registerLazySingleton<PlacesRemoteDataSource>(
    () => PlacesRemoteDataSource(),
  );
  sl.registerLazySingleton<PlacesRepository>(
    () => PlacesRepository(sl<PlacesRemoteDataSource>()),
  );
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<SessionCubit>(), sl<RideRequestRepository>()),
  );

  // ─── Booking Feature ────────────────────────────────────────
  sl.registerFactory<BookingCubit>(() => BookingCubit());

  // ─── Tracking Feature ───────────────────────────────────────
  sl.registerFactory<TrackingCubit>(() => TrackingCubit());

  // ─── Trips Feature ──────────────────────────────────────────
  sl.registerFactory<TripsCubit>(() => TripsCubit());

  // ─── Settings Feature ───────────────────────────────────────
  sl.registerFactory<SettingsCubit>(() => SettingsCubit(sl<SessionCubit>()));

  // ─── Favorites Feature ──────────────────────────────────────
  sl.registerFactory<FavoritesCubit>(() => FavoritesCubit());

  // ─── Notifications Feature ──────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepository(sl<NotificationsRemoteDataSource>()),
  );
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(sl<NotificationsRepository>()),
  );
}
