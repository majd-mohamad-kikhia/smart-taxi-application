import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/auth_header_widget.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/role_option_card_widget.dart';

/// First screen of the auth flow: the user picks whether they are
/// signing up/in as a rider or as a driver before reaching the sign
/// in / sign up forms.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  AuthCubit get _cubit => sl<AuthCubit>();

  void _continue() {
    final role = _selected;
    if (role == null) return;
    _cubit.selectRole(role);
    Navigator.of(context).pushNamed(
      role == UserRole.driver ? AppRouter.driverSignIn : AppRouter.signIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXXL),
          child: Column(
            children: [
              const Spacer(),
              AuthHeaderWidget(
                title: context.l10n.welcomeToApp,
                subtitle: context.l10n.chooseAccountType,
              ),
              const SizedBox(height: AppConstants.paddingXXL),
              RoleOptionCardWidget(
                role: UserRole.rider,
                icon: Icons.person_rounded,
                isSelected: _selected == UserRole.rider,
                onTap: () => setState(() => _selected = UserRole.rider),
              ),
              const SizedBox(height: AppConstants.paddingM),
              RoleOptionCardWidget(
                role: UserRole.driver,
                icon: Icons.local_taxi_rounded,
                isSelected: _selected == UserRole.driver,
                onTap: () => setState(() => _selected = UserRole.driver),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _continue,
                  child: Text(context.l10n.continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
