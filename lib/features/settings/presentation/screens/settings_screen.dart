import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/complaints/complaint_cubit.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/complaint_button_widget.dart';
import '../../../../core/widgets/contact_us_button_widget.dart';
import '../../../../core/widgets/complaint_dialog_widget.dart';
import '../../../../core/widgets/language_dropdown_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../../core/widgets/privacy_policy_button_widget.dart';
import '../../../../core/widgets/privacy_policy_dialog_widget.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../../../../core/widgets/delete_account_button_widget.dart';
import '../widgets/delete_account_dialog_widget.dart';
import '../widgets/profile_card_widget.dart';

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
        child: AppBrandBarWidget(showNotifications: true),
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
              const SizedBox(height: 14),
              const LanguageDropdownWidget(),
              const SizedBox(height: 14),
              PrivacyPolicyButtonWidget(
                onPressed: () => showPrivacyPolicyDialog(context),
              ),
              const SizedBox(height: 12),
              ContactUsButtonWidget(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRouter.contactUs,
                  arguments: UserRole.rider,
                ),
              ),
              const SizedBox(height: 12),
              ComplaintButtonWidget(
                onPressed: () => _openComplaintDialog(context),
              ),
              const SizedBox(height: 12),
              LogoutFooterWidget(
                isLoading: state.isLoggingOut,
                onLogout: () => _confirmLogout(context),
                belowLogout: DeleteAccountButtonWidget(
                  onPressed: () => _openDeleteAccountDialog(context),
                ),
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
      onSubmitted: () => showAppSnackBar(
        context,
        context.l10n.complaintSent,
        type: AppSnackBarType.success,
      ),
    );
  }

  void _openDeleteAccountDialog(BuildContext context) {
    // The messenger and navigator outlive this screen, which is removed
    // from the stack as soon as the account is deleted.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final message = context.l10n.deleteAccountDone;
    showDeleteAccountDialog(
      context,
      createCubit: () => sl<DeleteAccountCubit>(),
      onDeleted: () {
        navigator.pushNamedAndRemoveUntil(
          AppRouter.roleSelection,
          (route) => false,
        );
        showAppSnackBarOn(messenger, message, type: AppSnackBarType.success);
      },
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
