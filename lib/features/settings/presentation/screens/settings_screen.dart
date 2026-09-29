import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/complaints/complaint_cubit.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/coming_soon_screen_widget.dart';
import '../../../../core/widgets/complaint_button_widget.dart';
import '../../../../core/widgets/complaint_dialog_widget.dart';
import '../../../../core/widgets/language_dropdown_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../../core/widgets/terms_button_widget.dart';
import '../../../../core/widgets/terms_dialog_widget.dart';
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
                onEdit: () => _openEditProfile(context),
              ),
              const SizedBox(height: 18),
              SettingsSectionsWidget(
                sections: state.sections,
                onItemTapped: (id) {
                  context.read<SettingsCubit>().onItemTapped(id);
                  if (id == 'favorites') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComingSoonScreenWidget(
                          label: context.l10n.favoritePlaces,
                        ),
                      ),
                    );
                  }
                },
              ),
              const LanguageDropdownWidget(),
              const SizedBox(height: 14),
              TermsButtonWidget(
                onPressed: () => showTermsDialog(context, role: UserRole.rider),
              ),
              const SizedBox(height: 12),
              ComplaintButtonWidget(
                onPressed: () => _openComplaintDialog(context),
              ),
              const SizedBox(height: 12),
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

  Future<void> _openEditProfile(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final saved = await Navigator.of(context).pushNamed(AppRouter.editProfile);
    if (saved == true) cubit.initialize();
  }

  void _openComplaintDialog(BuildContext context) {
    showComplaintDialog(
      context,
      createCubit: () => sl<ComplaintCubit>(instanceName: 'customer'),
      onSubmitted: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.complaintSent))),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = context.l10n;
    showAppDialog(
      context: context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessageRider,
      confirmLabel: l10n.logoutConfirm,
      cancelLabel: l10n.goBack,
      icon: Icons.logout_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => _logout(context),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    await cubit.logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.roleSelection, (route) => false);
  }
}
