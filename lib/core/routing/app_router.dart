import 'package:flutter/material.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';

/// Centralized route definitions for the Mshoar app.
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String booking = '/booking';
  static const String tracking = '/tracking';
  static const String trips = '/trips';
  static const String settings = '/settings';
  static const String favorites = '/favorites';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
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
      default:
        return _buildRoute(const HomeScreen());
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
    );
  }
}
