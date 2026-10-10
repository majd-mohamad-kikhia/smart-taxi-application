import 'package:flutter/material.dart';
import '../app_version/data/models/app_version_model.dart';
import '../app_version/presentation/screens/force_update_screen.dart';
import '../app_version/presentation/screens/maintenance_screen.dart';
import '../contact_us/presentation/screens/contact_us_screen.dart';
import '../enums/user_role.dart';
import '../session/app_user.dart';
import '../../driver_features/driver_auth/presentation/screens/driver_sign_in_screen.dart';
import '../../driver_features/driver_auth/presentation/screens/driver_sign_up_screen.dart';
import '../../driver_features/driver_auth/presentation/screens/driver_signup_pending_screen.dart';
import '../../driver_features/driver_gps_guard/presentation/widgets/driver_gps_guard_widget.dart';
import '../../driver_features/driver_main_wrapper_screen.dart';
import '../../driver_features/driver_ratings/presentation/screens/driver_ratings_screen.dart';
import '../../driver_features/driver_shared_order/presentation/screens/shared_order_screen.dart';
import '../../driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import '../../driver_features/driver_trip/presentation/screens/driver_trip_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/home/presentation/screens/location_picker_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/saved_addresses/presentation/screens/saved_address_form_screen.dart';
import '../../features/saved_addresses/presentation/screens/saved_addresses_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/ride_tracking_screen.dart';
import '../../features/trips/presentation/screens/ride_details_screen.dart';
import '../models/order_offer_model.dart';
import '../models/picked_location_model.dart';
import '../models/ride_model.dart';
import '../saved_addresses/data/models/saved_address_model.dart';
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

/// Arguments for [AppRouter.locationPicker], which pops the chosen
/// [PickedLocationModel].
class LocationPickerRouteArgs {
  final String title;
  final bool isPickup;
  final PickedLocationModel? initialLocation;

  const LocationPickerRouteArgs({
    required this.title,
    required this.isPickup,
    this.initialLocation,
  });
}

/// Arguments for [AppRouter.savedAddressForm]: a new place of [type], or
/// [existing] to edit. The screen pops `replaced` (bool) once saved.
class SavedAddressFormRouteArgs {
  final SavedAddressType type;
  final SavedAddressModel? existing;

  const SavedAddressFormRouteArgs({required this.type, this.existing});
}

class AppRouter {
  AppRouter._();

  static const String roleSelection = '/role-selection';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String driverSignIn = '/driver/sign-in';
  static const String driverSignUp = '/driver/sign-up';
  static const String driverSignupPending = '/driver/signup-pending';
  static const String driverHome = '/driver/home';
  static const String driverTrip = '/driver/trip';

  /// An office order opened from its WhatsApp link; takes the link's token
  /// (String) as `RouteSettings.arguments`.
  static const String driverSharedOrder = '/driver/shared-order';
  static const String driverRatings = '/driver/ratings';
  static const String home = '/';
  static const String rideTracking = '/ride-tracking';
  static const String rideDetails = '/trips/details';
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String notifications = '/notifications';
  static const String locationPicker = '/location-picker';
  static const String savedAddresses = '/settings/saved-addresses';
  static const String savedAddressForm = '/settings/saved-addresses/form';

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
          settings,
          ForceUpdateScreen(info: settings.arguments! as AppVersionModel),
        );
      case maintenance:
        return _buildRoute(
          settings,
          MaintenanceScreen(info: settings.arguments! as AppVersionModel),
        );
      case roleSelection:
        return _buildRoute(settings, const RoleSelectionScreen());
      case signIn:
        return _buildRoute(settings, const SignInScreen());
      case signUp:
        return _buildRoute(settings, const SignUpScreen());
      case driverSignIn:
        return _buildRoute(settings, const DriverSignInScreen());
      case driverSignUp:
        return _buildRoute(settings, const DriverSignUpScreen());
      case driverSignupPending:
        return _buildRoute(settings, const DriverSignupPendingScreen());
      case driverHome:
        return _buildRoute(
          settings,
          const DriverGpsGuardWidget(child: DriverMainWrapperScreen()),
        );
      case driverTrip:
        final args = settings.arguments! as DriverTripRouteArgs;
        return _buildRoute(
          settings,
          DriverGpsGuardWidget(
            child: DriverTripScreen(order: args.order, resume: args.resume),
          ),
        );
      case driverRatings:
        return _buildRoute(settings, const DriverRatingsScreen());
      case driverSharedOrder:
        return _buildRoute(
          settings,
          SharedOrderScreen(token: settings.arguments! as String),
        );
      case home:
        return _buildRoute(settings, const MainWrapperScreen());
      case rideTracking:
        final args = settings.arguments! as RideTrackingRouteArgs;
        return _buildRoute(
          settings,
          RideTrackingScreen(
            initialRide: args.initialRide,
            pickup: args.pickup,
            dropoff: args.dropoff,
          ),
        );
      case rideDetails:
        return _buildRoute(
          settings,
          RideDetailsScreen(rideId: settings.arguments! as int),
        );
      case AppRouter.settings:
        return _buildRoute(settings, const SettingsScreen());
      case editProfile:
        return _buildRoute(settings, const EditProfileScreen());
      case notifications:
        return _buildRoute(settings, const NotificationsScreen());
      case locationPicker:
        final args = settings.arguments! as LocationPickerRouteArgs;
        return _buildRoute(
          settings,
          LocationPickerScreen(
            title: args.title,
            isPickup: args.isPickup,
            initialLocation: args.initialLocation,
          ),
        );
      case savedAddresses:
        return _buildRoute(settings, const SavedAddressesScreen());
      case savedAddressForm:
        final args = settings.arguments! as SavedAddressFormRouteArgs;
        return _buildRoute(
          settings,
          SavedAddressFormScreen(type: args.type, existing: args.existing),
        );
      case contactUs:
        return _buildRoute(
          settings,
          ContactUsScreen(role: settings.arguments! as UserRole),
        );
      default:
        return _buildRoute(settings, const MainWrapperScreen());
    }
  }

  /// Keeps [settings] on the route so code can find a screen in the stack
  /// by name (e.g. the deep-link handler looking for role selection).
  static MaterialPageRoute<T> _buildRoute<T>(RouteSettings settings, Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page, settings: settings);
  }
}
