import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/complaints/complaint_cubit.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/complaint_button_widget.dart';
import '../../../../core/widgets/contact_us_button_widget.dart';
import '../../../../core/widgets/complaint_dialog_widget.dart';
import '../../../../core/widgets/language_dropdown_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../../core/widgets/privacy_policy_button_widget.dart';
import '../../../../core/widgets/privacy_policy_dialog_widget.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_settings_cubit.dart';
import '../cubit/driver_settings_state.dart';
import '../widgets/driver_account_deletion_section_widget.dart';
import '../widgets/search_radius_slider_widget.dart';

/// Driver settings tab — search radius control plus the logout action,
/// matching the customer app's settings footer.
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
      tone: AppDialogTone.destructive,
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

  void _openComplaintDialog(BuildContext context) {
    showComplaintDialog(
      context,
      createCubit: () => sl<ComplaintCubit>(instanceName: 'driver'),
      onSubmitted: () =>
          showAppSnackBar(
            context,
            context.l10n.complaintSent,
            type: AppSnackBarType.success,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBrandBarWidget(),
      ),
      body: BlocBuilder<DriverAuthCubit, DriverAuthState>(
        bloc: sl<DriverAuthCubit>(),
        builder: (context, state) {
          return BlocConsumer<DriverSettingsCubit, DriverSettingsState>(
            bloc: _settingsCubit,
            listener: (context, settingsState) {
              if (settingsState.saveStatus == SearchRadiusSaveStatus.success) {
                showAppSnackBar(
                  context,
                  context.l10n.searchRadiusSaved,
                  type: AppSnackBarType.success,
                );
              } else if (settingsState.saveStatus ==
                  SearchRadiusSaveStatus.failure) {
                showAppSnackBar(
                  context,
                  settingsState.errorMessage ??
                      context.l10n.searchRadiusSaveFailed,
                  type: AppSnackBarType.error,
                );
              }
            },
            builder: (context, settingsState) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const LanguageDropdownWidget(),
                  const SizedBox(height: 12),
                  SearchRadiusSliderWidget(
                    valueKm: settingsState.searchRadiusKm,
                    onChanged: _settingsCubit.setSearchRadius,
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButtonWidget(
                    label: context.l10n.save,
                    isLoading:
                        settingsState.saveStatus ==
                        SearchRadiusSaveStatus.saving,
                    onPressed: _settingsCubit.saveSearchRadius,
                  ),
                  const SizedBox(height: 20),
                  PrivacyPolicyButtonWidget(
                    onPressed: () => showPrivacyPolicyDialog(context),
                  ),
                  const SizedBox(height: 12),
                  ContactUsButtonWidget(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRouter.contactUs,
                      arguments: UserRole.driver,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ComplaintButtonWidget(
                    onPressed: () => _openComplaintDialog(context),
                  ),
                  const SizedBox(height: 24),
                  LogoutFooterWidget(
                    isLoading: _isLoggingOut,
                    onLogout: () => _confirmLogout(context),
                    belowLogout: const DriverAccountDeletionSectionWidget(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
