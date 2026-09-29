import 'package:flutter/material.dart';
import '../core/injection/injection.dart';
import '../core/l10n/generated/app_localizations.dart';
import '../core/localization/l10n_context_extension.dart';
import '../core/widgets/app_bottom_nav_widget.dart';
import 'driver_home/presentation/screens/driver_home_screen.dart';
import 'driver_profile/presentation/screens/driver_profile_screen.dart';
import 'driver_settings/presentation/screens/driver_settings_screen.dart';
import 'driver_trip/data/repositories/driver_trip_route_repository.dart';
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

class _DriverMainWrapperScreenState extends State<DriverMainWrapperScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Upload routes of earlier trips that never reached the server (app
    // killed / offline at finish). Fire and forget — it never throws.
    sl<DriverTripRouteRepository>().uploadPending();
  }

  static const List<Widget> _tabs = [
    DriverHomeScreen(),
    DriverWalletScreen(),
    DriverProfileScreen(),
    DriverSettingsScreen(),
  ];

  List<AppNavItem> _navItems(AppLocalizations l10n) => [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.navHome),
    AppNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: l10n.navWallet),
    AppNavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: l10n.navProfile),
    AppNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: l10n.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavWidget(
        currentIndex: _currentIndex,
        items: _navItems(context.l10n),
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
