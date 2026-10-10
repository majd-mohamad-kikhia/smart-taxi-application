import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/injection/injection.dart';
import '../core/l10n/generated/app_localizations.dart';
import '../core/localization/l10n_context_extension.dart';
import '../core/routing/app_router.dart';
import '../core/widgets/app_bottom_nav_widget.dart';
import '../core/widgets/app_snack_bar_widget.dart';
import 'driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'driver_home/data/datasources/driver_socket_service.dart';
import 'driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'driver_home/presentation/screens/driver_home_screen.dart';
import 'driver_ratings/data/models/driver_ratings_page_model.dart';
import 'driver_profile/presentation/screens/driver_profile_screen.dart';
import 'driver_route/presentation/screens/driver_route_screen.dart';
import 'driver_settings/presentation/screens/driver_settings_screen.dart';
import 'driver_trip/data/repositories/driver_trip_route_repository.dart';
import 'driver_trip/presentation/cubit/driver_active_ride_cubit.dart';
import 'driver_trip/presentation/cubit/driver_active_ride_state.dart';
import 'driver_wallet/presentation/screens/driver_wallet_screen.dart';

/// Persistent shell for the driver app's tabs (Home, Profile, Settings) —
/// the driver's own equivalent of the customer app's `MainWrapperScreen`.
/// Keeps every tab mounted in an [IndexedStack] and swaps only the active
/// index on tap, so switching tabs never pushes a new route.
class DriverMainWrapperScreen extends StatefulWidget {
  const DriverMainWrapperScreen({super.key});

  @override
  State<DriverMainWrapperScreen> createState() => _DriverMainWrapperScreenState();
}

class _DriverMainWrapperScreenState extends State<DriverMainWrapperScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final StreamSubscription<Map<String, dynamic>> _ratingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Online before the app was closed: connect again without waiting for
    // the toggle.
    sl<DriverPresenceCubit>().resumeIfWasOnline();
    _ratingSubscription = sl<DriverSocketService>().ratingReceived.listen(
      _onRatingReceived,
    );
    // Upload routes of earlier trips that never reached the server (app
    // killed / offline at finish). Fire and forget — it never throws.
    sl<DriverTripRouteRepository>().uploadPending();
  }

  /// A customer rated this driver: say so, and keep the profile's average
  /// current.
  void _onRatingReceived(Map<String, dynamic> json) {
    final rating = DriverRatingReceivedModel.tryParse(json);
    if (rating == null || !mounted) return;
    final average = rating.average;
    if (average != null) sl<DriverAuthCubit>().applyRating(average);
    showAppSnackBar(
      context,
      context.l10n.newRatingToast(rating.stars),
      type: AppSnackBarType.success,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The socket may have died while the app was in the background.
    if (state == AppLifecycleState.resumed) {
      sl<DriverPresenceCubit>().resumeIfWasOnline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ratingSubscription.cancel();
    super.dispose();
  }

  static const List<Widget> _tabs = [
    DriverHomeScreen(),
    DriverRouteScreen(),
    DriverWalletScreen(),
    DriverProfileScreen(),
    DriverSettingsScreen(),
  ];

  List<AppNavItem> _navItems(AppLocalizations l10n) => [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.navHome),
    AppNavItem(icon: Icons.route_outlined, activeIcon: Icons.route_rounded, label: l10n.navRoute),
    AppNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: l10n.navWallet),
    AppNavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: l10n.navProfile),
    AppNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: l10n.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverActiveRideCubit>(
      create: (_) => sl<DriverActiveRideCubit>()..checkForActiveRide(),
      child: BlocListener<DriverActiveRideCubit, DriverActiveRideState>(
        listenWhen: (previous, current) =>
            current.ride != null && current.version != previous.version,
        // The app was closed mid-ride, or the office assigned a trip: open
        // the trip screen (and its waiting timer) instead of leaving the
        // driver on the home tab.
        listener: (context, state) {
          if (state.isAssigned) {
            showAppSnackBar(
              context,
              context.l10n.tripAssignedToYou,
              type: AppSnackBarType.info,
            );
          }
          Navigator.of(context).pushNamed(
            AppRouter.driverTrip,
            arguments: DriverTripRouteArgs(order: state.ride!.order, resume: state.ride),
          );
        },
        child: Scaffold(
          body: IndexedStack(index: _currentIndex, children: _tabs),
          bottomNavigationBar: AppBottomNavWidget(
            currentIndex: _currentIndex,
            items: _navItems(context.l10n),
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ),
      ),
    );
  }
}
