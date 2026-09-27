import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_bottom_nav_widget.dart';
import '../../../../core/widgets/app_nav_helper.dart';
import '../../../home/presentation/widgets/home_app_bar_widget.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/logout_footer_widget.dart';
import '../widgets/profile_card_widget.dart';
import '../widgets/settings_sections_widget.dart';
import '../widgets/wallet_card_widget.dart';

/// Profile / Settings screen with wallet, preferences, and logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => sl<SettingsCubit>()..initialize(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: HomeAppBarWidget(),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ProfileCardWidget(
                profile: state.profile,
                onEdit: () =>
                    context.read<SettingsCubit>().onItemTapped('edit_profile'),
              ),
              const SizedBox(height: 14),
              WalletCardWidget(
                balanceLabel: state.profile.walletLabel,
                onRecharge: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('شحن الرصيد قريباً'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              SettingsSectionsWidget(
                sections: state.sections,
                notificationsEnabled: state.notificationsEnabled,
                onNotificationsChanged: (v) =>
                    context.read<SettingsCubit>().toggleNotifications(v),
                onItemTapped: (id) {
                  context.read<SettingsCubit>().onItemTapped(id);
                  if (id == 'favorites') {
                    Navigator.of(context).pushNamed(AppRouter.favorites);
                  }
                },
              ),
              LogoutFooterWidget(
                isLoading: state.isLoggingOut,
                onLogout: () => _confirmLogout(context),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavWidget(
        currentIndex: 3,
        onTap: (i) => AppNavHelper.handleTap(context, i, current: 3),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'تسجيل الخروج؟',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟ ستحتاج لتسجيل الدخول مجدداً للمتابعة.',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'تراجع',
      icon: Icons.logout_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => context.read<SettingsCubit>().logout(),
    );
  }
}
