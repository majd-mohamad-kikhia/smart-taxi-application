import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/coming_soon_screen_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../home/presentation/widgets/home_app_bar_widget.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/profile_card_widget.dart';
import '../widgets/settings_sections_widget.dart';

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
              const SizedBox(height: 18),
              SettingsSectionsWidget(
                sections: state.sections,
                onItemTapped: (id) {
                  context.read<SettingsCubit>().onItemTapped(id);
                  if (id == 'favorites') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ComingSoonScreenWidget(
                          label: 'الأماكن المفضلة',
                        ),
                      ),
                    );
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
    );
  }

  void _confirmLogout(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'تسجيل الخروج؟',
      message:
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟ ستحتاج لتسجيل الدخول مجدداً للمتابعة.',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'تراجع',
      icon: Icons.logout_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => _logout(context),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    await cubit.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.roleSelection,
      (route) => false,
    );
  }
}
