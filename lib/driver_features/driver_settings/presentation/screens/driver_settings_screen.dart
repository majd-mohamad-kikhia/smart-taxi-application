import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/complaints/complaint_cubit.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/account_deletion_notice_dialog_widget.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/complaint_dialog_widget.dart';
import '../../../../core/widgets/language_dropdown_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../../core/widgets/privacy_policy_dialog_widget.dart';
import '../../../../core/widgets/settings_row_widget.dart';
import '../../../../core/widgets/settings_section_widget.dart';
import '../cubit/driver_settings_cubit.dart';
import '../cubit/driver_settings_state.dart';
import '../widgets/driver_account_deletion_section_widget.dart';
import '../widgets/search_radius_slider_widget.dart';

/// Driver settings tab — the trip search radius, language, help, and the
/// account actions, in that order, matching the customer app's settings.
class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _isLoggingOut = false;
  late final DriverSettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = sl<DriverSettingsCubit>();
  }

  @override
  void dispose() {
    _settingsCubit.close();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    final l10n = context.l10n;
    showAppDialog(
      context: context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessageDriver,
      confirmLabel: l10n.logoutConfirm,
      cancelLabel: l10n.goBack,
      icon: Icons.logout_rounded,
      // Logging out is reversible; red is kept for deleting the account.
      tone: AppDialogTone.primary,
      onConfirm: () => _logout(context),
    );
  }

  Future<void> _logout(BuildContext context) async {
    setState(() => _isLoggingOut = true);
    await sl<SessionCubit>().logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.roleSelection, (route) => false);
  }

  /// The request is with the manager. Say how long the removal takes, then
  /// sign this device out and leave for the first screen.
  void _onDeletionRequested(BuildContext context) {
    if (!context.mounted) return;
    showAccountDeletionNoticeDialog(
      context,
      onContinue: () => _logout(context),
    );
  }

  void _openComplaintDialog(BuildContext context) {
    showComplaintDialog(
      context,
      createCubit: () => sl<ComplaintCubit>(instanceName: 'driver'),
      onSubmitted: () => showAppSnackBar(
        context,
        context.l10n.complaintSent,
        type: AppSnackBarType.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocConsumer<DriverSettingsCubit, DriverSettingsState>(
        bloc: _settingsCubit,
        // Only a change of the save result speaks: dragging the slider after
        // a save must not repeat the old "saved" message.
        listenWhen: (previous, current) =>
            previous.saveStatus != current.saveStatus,
        listener: (context, settingsState) {
          if (settingsState.saveStatus == SearchRadiusSaveStatus.success) {
            showAppSnackBar(
              context,
              l10n.searchRadiusSaved,
              type: AppSnackBarType.success,
            );
          } else if (settingsState.saveStatus ==
              SearchRadiusSaveStatus.failure) {
            showAppSnackBar(
              context,
              settingsState.errorMessage ?? l10n.searchRadiusSaveFailed,
              type: AppSnackBarType.error,
            );
          }
        },
        builder: (context, settingsState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                children: [
                  SettingsHeadingWidget(title: l10n.settingsSectionTrips),
                  SearchRadiusSliderWidget(
                    valueKm: settingsState.searchRadiusKm,
                    isUnsaved: settingsState.hasUnsavedRadius,
                    onChanged: _settingsCubit.setSearchRadius,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  // Save works only while there is something to save.
                  AuthPrimaryButtonWidget(
                    label: l10n.save,
                    isLoading:
                        settingsState.saveStatus ==
                        SearchRadiusSaveStatus.saving,
                    onPressed: settingsState.hasUnsavedRadius
                        ? _settingsCubit.saveSearchRadius
                        : null,
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
                          arguments: UserRole.driver,
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
                    isLoading: _isLoggingOut,
                    onLogout: () => _confirmLogout(context),
                    belowLogout: DriverAccountDeletionSectionWidget(
                      onRequestSent: () => _onDeletionRequested(context),
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
}
