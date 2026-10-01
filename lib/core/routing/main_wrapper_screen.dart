import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/l10n_context_extension.dart';
import '../widgets/app_bottom_nav_widget.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';

/// Persistent shell for the main tab screens (Home, Trips,
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
    SettingsScreen(),
  ];

  List<AppNavItem> _navItems(AppLocalizations l10n) => [
    AppNavItem(icon: Icons.add_location_alt_outlined, activeIcon: Icons.add_location_alt_rounded, label: l10n.navCreateRequest),
    AppNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: l10n.navMyRequests),
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
