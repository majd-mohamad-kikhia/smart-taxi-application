import 'package:flutter/material.dart';
import '../../driver_features/driver_auth/presentation/screens/driver_sign_in_screen.dart';
import '../../driver_features/driver_main_wrapper_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import 'main_wrapper_screen.dart';

/// Centralized route definitions for the Mshoar app.
class AppRouter {
  AppRouter._();

  static const String roleSelection = '/role-selection';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String driverSignIn = '/driver/sign-in';
  static const String driverHome = '/driver/home';
  static const String home = '/';
  static const String booking = '/booking';
  static const String tracking = '/tracking';
  static const String trips = '/trips';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case roleSelection:
        return _buildRoute(const RoleSelectionScreen());
      case signIn:
        return _buildRoute(const SignInScreen());
      case signUp:
        return _buildRoute(const SignUpScreen());
      case driverSignIn:
        return _buildRoute(const DriverSignInScreen());
      case driverHome:
        return _buildRoute(const DriverMainWrapperScreen());
      case home:
        return _buildRoute(const MainWrapperScreen());
      case booking:
        return _buildRoute(const BookingScreen());
      case tracking:
        return _buildRoute(const TrackingScreen());
      case trips:
        return _buildRoute(const TripsScreen());
      case AppRouter.settings:
        return _buildRoute(const SettingsScreen());
      case favorites:
        return _buildRoute(const FavoritesScreen());
      case notifications:
        return _buildRoute(const NotificationsScreen());
      default:
        return _buildRoute(const MainWrapperScreen());
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
    );
  }
}
