import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/complaints/complaint_cubit.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/account_deletion_notice_dialog_widget.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/complaint_dialog_widget.dart';
import '../../../../core/widgets/language_dropdown_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../../core/widgets/privacy_policy_dialog_widget.dart';
import '../../../../core/widgets/settings_row_widget.dart';
import '../../../../core/widgets/settings_section_widget.dart';
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
          final l10n = context.l10n;
          // Three groups instead of eight loose controls: who you are, how
          // the app behaves, where to get help; then the account actions,
          // with the permanent one set well apart from logout.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingL,
                  AppConstants.paddingS,
                  AppConstants.paddingL,
                  AppConstants.paddingXXL,
                ),
                children: [
                  ProfileCardWidget(
                    profile: state.profile,
                    onEdit: () => _openEditProfile(context),
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),
                  SettingsSectionWidget(
                    title: l10n.settingsSectionTrips,
                    children: [
                      SettingsRowWidget(
                        icon: Icons.bookmark_border_rounded,
                        label: l10n.savedAddressesTitle,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.savedAddresses,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),
                  SettingsHeadingWidget(title: l10n.settingsSectionPreferences),
                  const LanguageDropdownWidget(),
                  const SizedBox(height: AppConstants.paddingXXL),
                  SettingsSectionWidget(
                    title: l10n.settingsSectionHelp,
                    children: [
                      SettingsRowWidget(
                        icon: Icons.privacy_tip_outlined,
                        label: l10n.privacyPolicy,
                        onTap: () => showPrivacyPolicyDialog(context),
                      ),
                      SettingsRowWidget(
                        icon: Icons.support_agent_rounded,
                        label: l10n.contactUs,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.contactUs,
                          arguments: UserRole.customer,
                        ),
                      ),
                      SettingsRowWidget(
                        icon: Icons.report_gmailerrorred_rounded,
                        label: l10n.complaintSend,
                        onTap: () => _openComplaintDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),
                  LogoutFooterWidget(
                    isLoading: state.isLoggingOut,
                    onLogout: () => _confirmLogout(context),
                    belowLogout: DeleteAccountButtonWidget(
                      onPressed: () => _openDeleteAccountDialog(context),
                    ),
                  ),
                ],
              ),
            ),
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
    showDeleteAccountDialog(
      context,
      createCubit: () => sl<DeleteAccountCubit>(),
      onDeleted: () {
        if (!context.mounted) return;
        // This device is already signed out; say how long the removal takes,
        // then leave for the first screen (the notice has no other exit).
        showAccountDeletionNoticeDialog(
          context,
          onContinue: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.roleSelection, (route) => false),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = context.l10n;
    showAppDialog(
      context: context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessageCustomer,
      confirmLabel: l10n.logoutConfirm,
      cancelLabel: l10n.goBack,
      icon: Icons.logout_rounded,
      // Logging out is reversible; red is kept for deleting the account.
      tone: AppDialogTone.primary,
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
