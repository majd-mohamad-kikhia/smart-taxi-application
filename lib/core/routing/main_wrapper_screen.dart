import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav_widget.dart';
import '../widgets/wallet_placeholder_widget.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';

/// Persistent shell for the main tab screens (Home, Trips, Wallet,
/// Settings). Keeps every tab mounted in an [IndexedStack] and swaps
/// only the active index on tap, so switching tabs no longer pushes
/// a new route or rebuilds the whole page.
class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    TripsScreen(),
    WalletPlaceholderWidget(),
    SettingsScreen(),
  ];

  static const List<AppNavItem> _navItems = [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'الرئيسية'),
    AppNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'طلباتي'),
    AppNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'المحفظة'),
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
