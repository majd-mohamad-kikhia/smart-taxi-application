import 'package:flutter/material.dart';
import '../app_version/data/models/app_version_model.dart';
import '../app_version/presentation/screens/force_update_screen.dart';
import '../app_version/presentation/screens/maintenance_screen.dart';
import '../contact_us/presentation/screens/contact_us_screen.dart';
import '../enums/user_role.dart';
import '../session/app_user.dart';
import '../../driver_features/driver_auth/presentation/screens/driver_sign_in_screen.dart';
import '../../driver_features/driver_gps_guard/presentation/widgets/driver_gps_guard_widget.dart';
import '../../driver_features/driver_main_wrapper_screen.dart';
import '../../driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import '../../driver_features/driver_trip/presentation/screens/driver_trip_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/ride_tracking_screen.dart';
import '../../features/trips/presentation/screens/ride_details_screen.dart';
import '../models/order_offer_model.dart';
import '../models/picked_location_model.dart';
import '../models/ride_model.dart';
import 'main_wrapper_screen.dart';

/// Arguments for [AppRouter.rideTracking] — a route that (unlike the
/// others here) needs constructor data, passed via `RouteSettings.arguments`
/// so `features/home` doesn't have to import a screen from
/// `features/tracking` directly (no cross-feature imports).
class RideTrackingRouteArgs {
  final RideModel initialRide;
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;

  const RideTrackingRouteArgs({
    required this.initialRide,
    required this.pickup,
    required this.dropoff,
  });
}

/// Arguments for [AppRouter.driverTrip] — same reasoning as
/// [RideTrackingRouteArgs], on the driver side.
class DriverTripRouteArgs {
  final OrderOfferModel order;

  /// Set when the driver is being put back on a ride from before the app
  /// closed (`GET /api/driver/rides/active`); null for a freshly accepted
  /// order.
  final DriverActiveRideModel? resume;

  const DriverTripRouteArgs({required this.order, this.resume});
}

class AppRouter {
  AppRouter._();

  static const String roleSelection = '/role-selection';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String driverSignIn = '/driver/sign-in';
  static const String driverHome = '/driver/home';
  static const String driverTrip = '/driver/trip';
  static const String home = '/';
  static const String rideTracking = '/ride-tracking';
  static const String rideDetails = '/trips/details';
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String notifications = '/notifications';

  /// Takes the caller's [UserRole] as `RouteSettings.arguments` — it decides
  /// which app's numbers are listed.
  static const String contactUs = '/contact-us';

  /// Full-screen blockers from the app version check. Both take the
  /// [AppVersionModel] as `RouteSettings.arguments`.
  static const String forceUpdate = '/app-version/force-update';
  static const String maintenance = '/app-version/maintenance';

  /// Lets code above the [Navigator] (the app version gate) navigate.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Where a signed-in [user] (or nobody) lands when the app starts.
  static String routeForUser(AppUser? user) => switch (user?.role) {
    UserRole.customer => home,
    UserRole.driver => driverHome,
    null => roleSelection,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case forceUpdate:
        return _buildRoute(
          ForceUpdateScreen(info: settings.arguments! as AppVersionModel),
        );
      case maintenance:
        return _buildRoute(
          MaintenanceScreen(info: settings.arguments! as AppVersionModel),
        );
      case roleSelection:
        return _buildRoute(const RoleSelectionScreen());
      case signIn:
        return _buildRoute(const SignInScreen());
      case signUp:
        return _buildRoute(const SignUpScreen());
      case driverSignIn:
        return _buildRoute(const DriverSignInScreen());
      case driverHome:
        return _buildRoute(
          const DriverGpsGuardWidget(child: DriverMainWrapperScreen()),
        );
      case driverTrip:
        final args = settings.arguments! as DriverTripRouteArgs;
        return _buildRoute(
          DriverGpsGuardWidget(
            child: DriverTripScreen(order: args.order, resume: args.resume),
          ),
        );
      case home:
        return _buildRoute(const MainWrapperScreen());
      case rideTracking:
        final args = settings.arguments! as RideTrackingRouteArgs;
        return _buildRoute(
          RideTrackingScreen(
            initialRide: args.initialRide,
            pickup: args.pickup,
            dropoff: args.dropoff,
          ),
        );
      case rideDetails:
        return _buildRoute(
          RideDetailsScreen(rideId: settings.arguments! as int),
        );
      case AppRouter.settings:
        return _buildRoute(const SettingsScreen());
      case editProfile:
        return _buildRoute(const EditProfileScreen());
      case notifications:
        return _buildRoute(const NotificationsScreen());
      case contactUs:
        return _buildRoute(
          ContactUsScreen(role: settings.arguments! as UserRole),
        );
      default:
        return _buildRoute(const MainWrapperScreen());
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page);
  }
}
