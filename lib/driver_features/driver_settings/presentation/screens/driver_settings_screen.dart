import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/logout_footer_widget.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_state.dart';
import '../cubit/driver_settings_cubit.dart';
import '../cubit/driver_settings_state.dart';
import '../widgets/complaint_dialog_widget.dart';
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
    showAppDialog(
      context: context,
      title: 'تسجيل الخروج؟',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'تراجع',
      icon: Icons.logout_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () => _logout(context),
    );
  }

  Future<void> _logout(BuildContext context) async {
    setState(() => _isLoggingOut = true);
    await sl<SessionCubit>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.roleSelection,
      (route) => false,
    );
  }

  void _openComplaintDialog(BuildContext context) {
    showComplaintDialog(
      context,
      onSubmitted: () => _showSnackBar(context, 'تم إرسال البلاغ بنجاح ✓'),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: BlocBuilder<DriverAuthCubit, DriverAuthState>(
        bloc: sl<DriverAuthCubit>(),
        builder: (context, state) {
          return BlocConsumer<DriverSettingsCubit, DriverSettingsState>(
            bloc: _settingsCubit,
            listener: (context, settingsState) {
              if (settingsState.saveStatus == SearchRadiusSaveStatus.success) {
                _showSnackBar(context, 'تم حفظ نطاق البحث ✓');
              } else if (settingsState.saveStatus == SearchRadiusSaveStatus.failure) {
                _showSnackBar(
                  context,
                  settingsState.errorMessage ?? 'تعذر حفظ نطاق البحث',
                  isError: true,
                );
              }
            },
            builder: (context, settingsState) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SearchRadiusSliderWidget(
                    valueKm: settingsState.searchRadiusKm,
                    onChanged: _settingsCubit.setSearchRadius,
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButtonWidget(
                    label: 'حفظ',
                    isLoading: settingsState.saveStatus == SearchRadiusSaveStatus.saving,
                    onPressed: _settingsCubit.saveSearchRadius,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _openComplaintDialog(context),
                    icon: const Icon(Icons.report_gmailerrorred_rounded, size: 20),
                    label: const Text('إرسال بلاغ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LogoutFooterWidget(
                    isLoading: _isLoggingOut,
                    onLogout: () => _confirmLogout(context),
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
