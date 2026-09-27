import 'package:flutter/material.dart';
import '../core/widgets/app_bottom_nav_widget.dart';
import 'driver_home/presentation/screens/driver_home_screen.dart';
import 'driver_profile/presentation/screens/driver_profile_screen.dart';
import 'driver_settings/presentation/screens/driver_settings_screen.dart';
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

  static const List<Widget> _tabs = [
    DriverHomeScreen(),
    DriverWalletScreen(),
    DriverProfileScreen(),
    DriverSettingsScreen(),
  ];

  static const List<AppNavItem> _navItems = [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'الرئيسية'),
    AppNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'المحفظة'),
    AppNavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'الملف الشخصي'),
    AppNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavWidget(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
