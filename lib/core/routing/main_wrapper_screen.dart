import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../account_block/account_block_cubit.dart';
import '../account_block/account_block_state.dart';
import '../injection/injection.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/l10n_context_extension.dart';
import '../widgets/app_animated_dialog.dart';
import '../widgets/app_bottom_nav_widget.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/wallet/presentation/screens/customer_wallet_screen.dart';

/// Persistent shell for the main tab screens (Home, Trips, Wallet,
/// Settings). Keeps every tab mounted in an [IndexedStack] and swaps
/// only the active index on tap, so switching tabs no longer pushes
/// a new route or rebuilds the whole page.
///
/// Also the customer's home for the ordering block: it reloads the block on
/// resume and shows the server's text after a counted cancel or a block, on
/// whichever screen is open.
class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  static const int _walletTabIndex = 2;

  int _currentIndex = 0;
  late final AppLifecycleListener _lifecycle;

  /// Bumped when the "create order" tab is tapped, so the home screen clears
  /// its From and To points.
  final ValueNotifier<int> _resetHome = ValueNotifier<int>(0);
  /// Bumped when the wallet tab is opened, so it reloads the balance.
  final ValueNotifier<int> _refreshWallet = ValueNotifier<int>(0);
  late final List<Widget> _tabs = [
    HomeScreen(resetSignal: _resetHome),
    const TripsScreen(),
    CustomerWalletScreen(refreshSignal: _refreshWallet),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => sl<AccountBlockCubit>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _resetHome.dispose();
    _refreshWallet.dispose();
    super.dispose();
  }

  List<AppNavItem> _navItems(AppLocalizations l10n) => [
    AppNavItem(icon: Icons.add_location_alt_outlined, activeIcon: Icons.add_location_alt_rounded, label: l10n.navCreateRequest),
    AppNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: l10n.navMyRequests),
    AppNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: l10n.navWallet),
    AppNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: l10n.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBlockCubit, AccountBlockState>(
      bloc: sl<AccountBlockCubit>(),
      listenWhen: (previous, current) =>
          current.noticeCount > previous.noticeCount && current.notice != null,
      listener: (context, state) => _showNotice(state.notice!),
      child: Scaffold(
        // The tabs draw under the floating nav bar, which has no backdrop.
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: AppBottomNavWidget(
          currentIndex: _currentIndex,
          items: _navItems(context.l10n),
          onTap: (index) {
            if (index == 0) _resetHome.value++;
            if (index == _walletTabIndex) _refreshWallet.value++;
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }

  /// After the frame, so a screen closing itself in the same moment (the
  /// tracking screen after a cancel) doesn't take the dialog with it.
  void _showNotice(AccountBlockNotice notice) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = context.l10n;
      if (notice.blocked) setState(() => _currentIndex = 0);
      showAppDialog<void>(
        context: context,
        title: notice.blocked ? l10n.orderingBlockedTitle : l10n.cancelCountedTitle,
        message: notice.message,
        icon: notice.blocked ? Icons.block_rounded : Icons.warning_amber_rounded,
        tone: notice.blocked ? AppDialogTone.destructive : AppDialogTone.warning,
        cancelLabel: l10n.gotIt,
      );
    });
  }
}
