import 'package:get_it/get_it.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/tracking/presentation/cubit/tracking_cubit.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
/// Call once at app startup before [runApp].
void setupInjection() {
  // ─── Home Feature ───────────────────────────────────────────
  sl.registerFactory<HomeCubit>(() => HomeCubit());

  // ─── Booking Feature ────────────────────────────────────────
  sl.registerFactory<BookingCubit>(() => BookingCubit());

  // ─── Tracking Feature ───────────────────────────────────────
  sl.registerFactory<TrackingCubit>(() => TrackingCubit());

  // ─── Trips Feature ──────────────────────────────────────────
  sl.registerFactory<TripsCubit>(() => TripsCubit());

  // ─── Settings Feature ───────────────────────────────────────
  sl.registerFactory<SettingsCubit>(() => SettingsCubit());

  // ─── Favorites Feature ──────────────────────────────────────
  sl.registerFactory<FavoritesCubit>(() => FavoritesCubit());
}
