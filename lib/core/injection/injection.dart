import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import '../../driver_features/driver_auth/data/datasources/driver_local_data_source.dart';
import '../../driver_features/driver_auth/data/datasources/driver_remote_data_source.dart';
import '../../driver_features/driver_auth/data/repositories/driver_repository.dart';
import '../../driver_features/driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../driver_features/driver_home/data/datasources/driver_socket_service.dart';
import '../../driver_features/driver_home/data/datasources/new_order_alert.dart';
import '../../driver_features/driver_home/data/driver_presence_store.dart';
import '../../driver_features/driver_home/data/location_ticker.dart';
import '../../driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart';
import '../../driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import '../../driver_features/driver_profile/data/datasources/driver_vehicle_remote_data_source.dart';
import '../../driver_features/driver_profile/data/repositories/driver_vehicle_repository.dart';
import '../../driver_features/driver_profile/presentation/cubit/driver_vehicle_cubit.dart';
import '../../driver_features/driver_settings/data/datasources/driver_account_deletion_remote_data_source.dart';
import '../../driver_features/driver_settings/data/datasources/driver_complaints_remote_data_source.dart';
import '../../driver_features/driver_settings/data/repositories/driver_account_deletion_repository.dart';
import '../../driver_features/driver_settings/data/repositories/driver_complaints_repository.dart';
import '../../driver_features/driver_settings/presentation/cubit/driver_account_deletion_cubit.dart';
import '../app_version/data/datasources/app_version_local_datasource.dart';
import '../app_version/data/datasources/app_version_remote_datasource.dart';
import '../app_version/data/repositories/app_version_repository.dart';
import '../app_version/presentation/cubit/app_version_cubit.dart';
import '../complaints/complaint_cubit.dart';
import '../../driver_features/driver_ratings/data/datasources/driver_ratings_remote_data_source.dart';
import '../../driver_features/driver_ratings/data/repositories/driver_ratings_repository.dart';
import '../../driver_features/driver_ratings/presentation/cubit/driver_ratings_cubit.dart';
import '../ride_rating/data/datasources/ride_rating_remote_data_source.dart';
import '../ride_rating/data/repositories/ride_rating_repository.dart';
import '../ride_rating/presentation/cubit/ride_rating_cubit.dart';
import '../contact_us/data/datasources/contact_us_remote_datasource.dart';
import '../contact_us/data/models/contact_number_model.dart';
import '../contact_us/data/repositories/contact_us_repository.dart';
import '../contact_us/presentation/cubit/contact_us_cubit.dart';
import '../../driver_features/driver_settings/presentation/cubit/driver_settings_cubit.dart';
import '../../driver_features/driver_gps_guard/data/datasources/gps_status_service.dart';
import '../../driver_features/driver_gps_guard/presentation/cubit/gps_status_cubit.dart';
import '../../driver_features/driver_route/data/datasources/route_location_service.dart';
import '../../driver_features/driver_route/data/datasources/route_session_local_data_source.dart';
import '../../driver_features/driver_route/data/repositories/route_session_repository.dart';
import '../../driver_features/driver_route/presentation/cubit/route_tracker_cubit.dart';
import '../../driver_features/driver_trip/data/datasources/driver_trip_location_service.dart';
import '../../driver_features/driver_trip/data/datasources/driver_trip_remote_data_source.dart';
import '../../driver_features/driver_trip/data/datasources/driver_trip_route_local_data_source.dart';
import '../../driver_features/driver_trip/data/datasources/open_trip_registry.dart';
import '../../driver_features/driver_trip/data/datasources/ride_bill_pdf_builder.dart';
import '../../driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import '../../driver_features/driver_trip/data/repositories/driver_trip_route_repository.dart';
import '../../driver_features/driver_trip/data/repositories/driver_trip_repository.dart';
import '../../driver_features/driver_trip/data/repositories/ride_bill_repository.dart';
import '../../driver_features/driver_trip/data/repositories/share_ride_info_repository.dart';
import '../../driver_features/driver_trip/presentation/cubit/driver_active_ride_cubit.dart';
import '../../driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart';
import '../../driver_features/driver_trip/presentation/cubit/ride_bill_cubit.dart';
import '../../driver_features/driver_trip/presentation/cubit/share_ride_info_cubit.dart';
import '../../driver_features/driver_shared_order/data/datasources/shared_order_remote_data_source.dart';
import '../../driver_features/driver_shared_order/data/repositories/shared_order_repository.dart';
import '../../driver_features/driver_shared_order/presentation/cubit/shared_order_cubit.dart';
import '../deep_links/deep_link_service.dart';
import '../deep_links/shared_order_link_handler.dart';
import '../../driver_features/driver_wallet/data/datasources/driver_wallet_remote_data_source.dart';
import '../../driver_features/driver_wallet/data/models/wallet_transaction_model.dart';
import '../../driver_features/driver_wallet/data/repositories/driver_wallet_repository.dart';
import '../../driver_features/driver_wallet/presentation/cubit/driver_financial_report_cubit.dart';
import '../../driver_features/driver_wallet/presentation/cubit/driver_wallet_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../enums/user_role.dart';
import '../localization/language_remote_data_source.dart';
import '../localization/language_repository.dart';
import '../localization/locale_cubit.dart';
import '../account_block/account_block_cubit.dart';
import '../account_block/account_block_remote_data_source.dart';
import '../account_block/account_block_repository.dart';
import '../account_block/account_block_socket_service.dart';
import '../privacy_policy/privacy_policy_cubit.dart';
import '../privacy_policy/privacy_policy_remote_data_source.dart';
import '../privacy_policy/privacy_policy_repository.dart';
import '../localization/locale_local_data_source.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_error_handler.dart';
import '../../features/home/data/datasources/google_places_data_source.dart';
import '../../features/home/data/datasources/nominatim_reverse_data_source.dart';
import '../services/current_location_service.dart';
import '../services/photo_picker_service.dart';
import '../../driver_features/driver_auth/presentation/cubit/driver_signup_cubit.dart';
import '../services/google_api_credentials_loader.dart';
import '../services/google_routes_service.dart';
import '../services/planned_route_loader.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/trip_route_tracker.dart';
import '../models/order_offer_model.dart';
import '../notifications/unread_notifications_cubit.dart';
import '../services/whatsapp_file_sender.dart';
import '../session/session_cubit.dart';
import '../../features/home/data/datasources/ride_request_remote_data_source.dart';
import '../../features/home/data/repositories/places_repository.dart';
import '../../features/home/data/repositories/ride_request_repository.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/cubit/map_pick_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/saved_addresses/presentation/cubit/saved_address_form_cubit.dart';
import '../saved_addresses/data/datasources/saved_addresses_remote_data_source.dart';
import '../saved_addresses/data/models/saved_address_model.dart';
import '../saved_addresses/data/repositories/saved_addresses_repository.dart';
import '../saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../features/settings/data/datasources/customer_complaints_remote_data_source.dart';
import '../../features/settings/data/datasources/profile_remote_data_source.dart';
import '../../features/settings/data/repositories/customer_complaints_repository.dart';
import '../../features/settings/data/repositories/profile_repository.dart';
import '../../features/settings/presentation/cubit/edit_profile_cubit.dart';
import '../../features/settings/presentation/cubit/delete_account_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/tracking/data/datasources/customer_ride_socket_service.dart';
import '../../features/tracking/presentation/cubit/ride_tracking_cubit.dart';
import '../../features/trips/data/datasources/trips_remote_data_source.dart';
import '../../features/trips/data/repositories/trips_repository.dart';
import '../../features/trips/presentation/cubit/ride_details_cubit.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';

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

  // ─── Core Localization ──────────────────────────────────────
  sl.registerLazySingleton<LanguageRepository>(
    () => LanguageRepository(
      LanguageRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
    ),
  );
  sl.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(
      const LocaleLocalDataSource(),
      sl<LanguageRepository>(),
      sl<SessionCubit>(),
    ),
  );

  // ─── Core Privacy Policy ────────────────────────────────────
  sl.registerLazySingleton<PrivacyPolicyRepository>(
    () => PrivacyPolicyRepository(
      PrivacyPolicyRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
    ),
  );
  sl.registerFactory<PrivacyPolicyCubit>(
    () => PrivacyPolicyCubit(sl<PrivacyPolicyRepository>()),
  );

  // ─── Core Contact Us ────────────────────────────────────────
  // One data source per app side, as singletons so each keeps its ETag cache
  // between visits; the cubit is created per screen.
  for (final app in ContactUsApp.values) {
    sl.registerLazySingleton<ContactUsRemoteDataSource>(
      () => ContactUsRemoteDataSource(
        sl<ApiClient>().dio,
        sl<ApiEndpoints>(),
        app: app,
      ),
      instanceName: app.wireValue,
    );
    sl.registerLazySingleton<ContactUsRepository>(
      () => ContactUsRepository(
        sl<ContactUsRemoteDataSource>(instanceName: app.wireValue),
      ),
      instanceName: app.wireValue,
    );
    sl.registerFactory<ContactUsCubit>(
      () => ContactUsCubit(
        sl<ContactUsRepository>(instanceName: app.wireValue),
      ),
      instanceName: app.wireValue,
    );
  }

  sl.registerLazySingleton<PhotoPickerService>(() => PhotoPickerService());
  // ─── Core Ride Rating ───────────────────────────────────────
  sl.registerLazySingleton<RideRatingRemoteDataSource>(
    () => RideRatingRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<RideRatingRepository>(
    () => RideRatingRepository(sl<RideRatingRemoteDataSource>()),
  );
  sl.registerFactoryParam<RideRatingCubit, int, void>(
    (rideId, _) => RideRatingCubit(sl<RideRatingRepository>(), rideId: rideId),
  );

  // ─── Core Session ───────────────────────────────────────────
  sl.registerLazySingleton<SessionCubit>(() => SessionCubit());

  // ─── Core Account Block ─────────────────────────────────────
  // Always-on socket feed of the ride block, for both roles (the customer's
  // is also loaded over REST and updated by block pushes). Runs
  // for as long as someone is signed in; restarted only when the account
  // (not just its profile fields) changes.
  sl.registerLazySingleton<AccountBlockSocketService>(
    () => AccountBlockSocketService(),
  );
  sl.registerLazySingleton<AccountBlockRepository>(
    () => AccountBlockRepository(
      AccountBlockRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
    ),
  );
  sl.registerLazySingleton<AccountBlockCubit>(
    () => AccountBlockCubit(
      sl<AccountBlockSocketService>(),
      sl<AccountBlockRepository>(),
      sl<PushNotificationService>().accountBlockPushes,
    ),
  );
  sl<SessionCubit>().stream.listen((user) {
    final cubit = sl<AccountBlockCubit>();
    if (user == null) {
      cubit.stop();
    } else {
      cubit.start(
        user.role,
        onAppVersionChanged: sl<AppVersionCubit>().onServerVersionChanged,
      );
    }
  });

  // ─── Core App Version ───────────────────────────────────────
  // Launch / resume / socket check of "may this version continue?" —
  // maintenance, force update, optional update. Singleton so the launch
  // check in `main`, the lifecycle gate and the socket listener share state.
  sl.registerLazySingleton<AppVersionRemoteDataSource>(
    () => AppVersionRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<AppVersionRepository>(
    () => AppVersionRepository(
      sl<AppVersionRemoteDataSource>(),
      const AppVersionLocalDataSource(),
    ),
  );
  sl.registerLazySingleton<AppVersionCubit>(
    () => AppVersionCubit(
      sl<AppVersionRepository>(),
      sl<LocaleCubit>(),
      sl<SessionCubit>(),
    ),
  );

  // ─── Deep Links ─────────────────────────────────────────────
  sl.registerLazySingleton<DeepLinkService>(() => DeepLinkService(AppLinks()));
  sl.registerLazySingleton<SharedOrderLinkHandler>(
    () => SharedOrderLinkHandler(
      sl<DeepLinkService>(),
      sl<SessionCubit>(),
      sl<AppVersionCubit>(),
    ),
  );

  // ─── Core Services ──────────────────────────────────────────
  sl.registerFactory<PlannedRouteLoader>(
    () => PlannedRouteLoader(sl<GoogleRoutesService>()),
  );
  // Every Google web API (Routes, Places, Geocoding) uses the
  // `GOOGLE_MAPS_API_KEY` from `.env`, which is loaded before injection is
  // set up (see main.dart).
  sl.registerLazySingleton<GoogleApiCredentialsLoader>(
    () => GoogleApiCredentialsLoader(
      envKey: dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '',
    ),
  );
  sl.registerLazySingleton<GoogleRoutesService>(
    () => GoogleRoutesService(credentials: sl<GoogleApiCredentialsLoader>().load),
  );
  sl.registerFactory<TripRouteTracker>(
    () => TripRouteTracker(sl<GoogleRoutesService>()),
  );
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
    UserRole.customer,
    () => sl<AuthCubit>().logout(),
  );
  // Role picked on the role-selection screen, before anyone is signed in:
  // the app version check is asked for that role (see AppVersionCubit).
  sl<AuthCubit>().stream
      .map((state) => state.selectedRole)
      .distinct()
      .listen((role) {
        if (role != null) sl<AppVersionCubit>().onRoleChosen(role);
      });
  // The bell's unread count follows the signed-in customer: asked for when
  // a customer signs in or is restored, cleared on logout.
  sl<SessionCubit>().stream.listen((user) {
    final unread = sl<UnreadNotificationsCubit>();
    if (user?.role == UserRole.customer) {
      unread.refresh();
    } else {
      unread.set(0);
    }
  });
  // Saved places follow the signed-in customer the same way.
  sl<SessionCubit>().stream
      .map((user) => user?.role == UserRole.customer ? user?.id : null)
      .distinct()
      .listen((customerId) {
        final savedAddresses = sl<SavedAddressesCubit>();
        if (customerId != null) {
          savedAddresses.load();
        } else {
          savedAddresses.clear();
        }
      });
  sl<SessionCubit>().stream.listen((user) {
    if (user == null || user.role != UserRole.customer) return;
    sl<AuthRepository>().syncStoredProfile(
      fullName: user.fullName,
      phone: user.phone,
      email: user.email,
      photoUrl: user.photoUrl,
    );
  });

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
    () => DriverRepository(
      sl<DriverRemoteDataSource>(),
      sl<DriverLocalDataSource>(),
    ),
  );
  // Singleton (not a factory) so the signed-in driver survives navigation
  // from sign in into the driver app shell.
  sl.registerFactory<DriverSignupCubit>(
    () => DriverSignupCubit(sl<DriverRepository>(), sl<PhotoPickerService>()),
  );
  sl.registerLazySingleton<DriverAuthCubit>(
    () => DriverAuthCubit(sl<DriverRepository>(), sl<SessionCubit>()),
  );
  sl<SessionCubit>().registerLogoutHandler(UserRole.driver, () async {
    await sl<DriverPresenceCubit>().goOffline();
    await sl<DriverAuthCubit>().logout();
  });

  // ─── Driver Home Feature ────────────────────────────────────
  // Singleton so `DriverPresenceCubit` and `DriverOrdersCubit` share one
  // Socket.IO connection instead of opening two.
  sl.registerLazySingleton<DriverSocketService>(() => DriverSocketService());
  sl.registerFactory<LocationTicker>(() => LocationTicker());
  sl.registerLazySingleton<DriverPresenceStore>(() => DriverPresenceStore());
  sl.registerLazySingleton<NewOrderAlert>(() => AudioNewOrderAlert());
  // Singleton so the live-location connection survives tab switches in
  // `DriverMainWrapperScreen`'s `IndexedStack`.
  sl.registerLazySingleton<DriverPresenceCubit>(
    () => DriverPresenceCubit(
      sl<DriverSocketService>(),
      sl<LocationTicker>(),
      sl<DriverPresenceStore>(),
    ),
  );
  // Singleton for the same reason — order cards must survive tab switches
  // and keep listening on the shared socket.
  sl.registerLazySingleton<DriverOrdersCubit>(
    () => DriverOrdersCubit(
      sl<DriverSocketService>(),
      sl<CurrentLocationService>(),
      sl<DriverPresenceCubit>(),
      sl<NewOrderAlert>(),
    ),
  );

  // ─── Driver Trip Feature ────────────────────────────────────
  sl.registerLazySingleton<DriverTripRemoteDataSource>(
    () => DriverTripRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<DriverTripLocationService>(
    () => DriverTripLocationService(),
  );
  sl.registerLazySingleton<DriverTripRepository>(
    () => DriverTripRepository(sl<DriverTripRemoteDataSource>()),
  );
  sl.registerLazySingleton<DriverTripRouteRepository>(
    () => DriverTripRouteRepository(
      sl<DriverTripRemoteDataSource>(),
      const DriverTripRouteLocalDataSource(),
    ),
  );
  sl.registerLazySingleton<OpenTripRegistry>(() => OpenTripRegistry());
  sl.registerLazySingleton<RideBillRepository>(
    () => const RideBillRepository(RideBillPdfBuilder(), WhatsAppFileSender()),
  );
  sl.registerFactory<RideBillCubit>(
    () => RideBillCubit(sl<RideBillRepository>(), sl<SessionCubit>()),
  );
  sl.registerLazySingleton<ShareRideInfoRepository>(
    () => ShareRideInfoRepository(sl<DriverTripRepository>()),
  );
  sl.registerFactory<ShareRideInfoCubit>(
    () => ShareRideInfoCubit(sl<ShareRideInfoRepository>(), sl<SessionCubit>()),
  );
  sl.registerFactoryParam<DriverTripCubit, OrderOfferModel, DriverActiveRideModel?>(
    (order, resume) => DriverTripCubit(
      sl<DriverTripRepository>(),
      sl<DriverTripLocationService>(),
      sl<PlannedRouteLoader>(),
      sl<DriverTripRouteRepository>(),
      sl<OpenTripRegistry>(),
      sl<DriverSocketService>().rideCancelled,
      sl<PushNotificationService>().rideCancelled,
      sl<DriverSocketService>().activeRide,
      order,
      resume: resume,
      pickupRouteTracker: sl<TripRouteTracker>(),
    ),
  );
  sl.registerFactory<DriverActiveRideCubit>(
    () => DriverActiveRideCubit(
      sl<DriverTripRepository>(),
      sl<DriverTripRouteRepository>(),
      sl<OpenTripRegistry>(),
      sl<DriverSocketService>().activeRide,
    ),
  );

  // ─── Driver Shared Order Feature ────────────────────────────
  sl.registerLazySingleton<SharedOrderRepository>(
    () => SharedOrderRepository(
      SharedOrderRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
      sl<CurrentLocationService>(),
    ),
  );
  sl.registerFactoryParam<SharedOrderCubit, String, void>(
    (token, _) => SharedOrderCubit(
      sl<SharedOrderRepository>(),
      sl<OpenTripRegistry>(),
      token: token,
      orderClosed: sl<DriverSocketService>().sharedOrderClosed,
      orderUpdated: sl<DriverSocketService>().sharedOrderUpdated,
      socketConnected: sl<DriverSocketService>().connected,
      isSocketConnected: () => sl<DriverSocketService>().isConnected,
    ),
  );

  // ─── Driver GPS Guard ───────────────────────────────────────
  // Singleton so every guarded driver screen shares one connection to the
  // system's GPS on/off events.
  sl.registerLazySingleton<GpsStatusCubit>(
    () => GpsStatusCubit(const GpsStatusService()),
  );

  // ─── Driver Route Feature (private, on-device only) ─────────
  sl.registerLazySingleton<RouteSessionRepository>(
    () => const RouteSessionRepository(RouteSessionLocalDataSource()),
  );
  sl.registerLazySingleton<RouteLocationService>(() => RouteLocationService());
  sl.registerFactory<RouteTrackerCubit>(
    () => RouteTrackerCubit(
      sl<RouteSessionRepository>(),
      sl<RouteLocationService>(),
      sl<CurrentLocationService>(),
    ),
  );

  // ─── Driver Settings Feature ────────────────────────────────
  sl.registerFactory<DriverSettingsCubit>(
    () => DriverSettingsCubit(sl<DriverAuthCubit>()),
  );
  sl.registerLazySingleton<DriverComplaintsRemoteDataSource>(
    () => DriverComplaintsRemoteDataSource(
      sl<ApiClient>().dio,
      sl<ApiEndpoints>(),
    ),
  );
  sl.registerLazySingleton<DriverComplaintsRepository>(
    () => DriverComplaintsRepository(sl<DriverComplaintsRemoteDataSource>()),
  );
  sl.registerFactory<ComplaintCubit>(
    () => ComplaintCubit(sl<DriverComplaintsRepository>().submitComplaint),
    instanceName: 'driver',
  );
  sl.registerLazySingleton<DriverAccountDeletionRemoteDataSource>(
    () => DriverAccountDeletionRemoteDataSource(
      sl<ApiClient>().dio,
      sl<ApiEndpoints>(),
    ),
  );
  sl.registerLazySingleton<DriverAccountDeletionRepository>(
    () => DriverAccountDeletionRepository(
      sl<DriverAccountDeletionRemoteDataSource>(),
    ),
  );
  sl.registerFactory<DriverAccountDeletionCubit>(
    () => DriverAccountDeletionCubit(sl<DriverAccountDeletionRepository>()),
  );

  // ─── Driver Ratings Feature ─────────────────────────────────
  sl.registerLazySingleton<DriverRatingsRemoteDataSource>(
    () => DriverRatingsRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<DriverRatingsRepository>(
    () => DriverRatingsRepository(sl<DriverRatingsRemoteDataSource>()),
  );
  sl.registerFactory<DriverRatingsCubit>(
    () => DriverRatingsCubit(sl<DriverRatingsRepository>()),
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
    () =>
        DriverVehicleRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
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
  sl.registerLazySingleton<PlacesRepository>(
    () => PlacesRepository(
      GooglePlacesDataSource(credentials: sl<GoogleApiCredentialsLoader>().load),
      NominatimReverseDataSource(),
    ),
  );
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      sl<SessionCubit>(),
      sl<RideRequestRepository>(),
      sl<AccountBlockCubit>(),
      sl<CurrentLocationService>(),
      sl<PlacesRepository>(),
    ),
  );

  sl.registerFactory<MapPickCubit>(
    () => MapPickCubit(sl<PlacesRepository>(), sl<CurrentLocationService>()),
  );

  // ─── Core Saved Addresses ───────────────────────────────────
  // Singleton cubit: the order screen's chips and the "Saved places" screen
  // share one list.
  sl.registerLazySingleton<SavedAddressesRepository>(
    () => SavedAddressesRepository(
      SavedAddressesRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
    ),
  );
  sl.registerLazySingleton<SavedAddressesCubit>(
    () => SavedAddressesCubit(sl<SavedAddressesRepository>()),
  );
  sl.registerFactoryParam<SavedAddressFormCubit, SavedAddressType, SavedAddressModel?>(
    (type, existing) => SavedAddressFormCubit(
      sl<SavedAddressesRepository>(),
      sl<SavedAddressesCubit>(),
      type: type,
      existing: existing,
    ),
  );

  // ─── Tracking Feature ───────────────────────────────────────
  // Real ride tracking (post choose-vehicle) — fresh socket + cubit per
  // screen visit, unlike the driver side's long-lived shared connection.
  sl.registerFactory<CustomerRideSocketService>(
    () => CustomerRideSocketService(),
  );
  sl.registerFactoryParam<RideTrackingCubit, RideTrackingCubitArgs, void>(
    (args, _) => RideTrackingCubit(
      sl<CustomerRideSocketService>(),
      sl<TripRouteTracker>(),
      sl<AccountBlockCubit>(),
      plannedRoutes: sl<GoogleRoutesService>(),
      initialRide: args.initialRide,
      pickup: args.pickup,
      dropoff: args.dropoff,
    ),
  );

  // ─── Trips Feature ──────────────────────────────────────────
  sl.registerLazySingleton<TripsRemoteDataSource>(
    () => TripsRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<TripsRepository>(
    () => TripsRepository(sl<TripsRemoteDataSource>()),
  );
  sl.registerFactory<TripsCubit>(() => TripsCubit(sl<TripsRepository>()));
  sl.registerFactoryParam<RideDetailsCubit, int, void>(
    (rideId, _) => RideDetailsCubit(sl<TripsRepository>(), rideId: rideId),
  );

  // ─── Settings Feature ───────────────────────────────────────
  sl.registerFactory<SettingsCubit>(() => SettingsCubit(sl<SessionCubit>()));
  sl.registerFactory<DeleteAccountCubit>(
    () => DeleteAccountCubit(sl<ProfileRepository>(), sl<SessionCubit>()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl<ProfileRemoteDataSource>()),
  );
  sl.registerLazySingleton<CustomerComplaintsRemoteDataSource>(
    () => CustomerComplaintsRemoteDataSource(
      sl<ApiClient>().dio,
      sl<ApiEndpoints>(),
    ),
  );
  sl.registerLazySingleton<CustomerComplaintsRepository>(
    () =>
        CustomerComplaintsRepository(sl<CustomerComplaintsRemoteDataSource>()),
  );
  sl.registerFactory<ComplaintCubit>(
    () => ComplaintCubit(sl<CustomerComplaintsRepository>().submitComplaint),
    instanceName: 'customer',
  );
  sl.registerFactory<EditProfileCubit>(
    () => EditProfileCubit(sl<ProfileRepository>(), sl<SessionCubit>()),
  );

  // ─── Notifications Feature ──────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(sl<ApiClient>().dio, sl<ApiEndpoints>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepository(sl<NotificationsRemoteDataSource>()),
  );
  sl.registerLazySingleton<UnreadNotificationsCubit>(
    () => UnreadNotificationsCubit(
      () => sl<NotificationsRepository>().getUnreadCount(),
    ),
  );
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      sl<NotificationsRepository>(),
      sl<UnreadNotificationsCubit>(),
    ),
  );
}
