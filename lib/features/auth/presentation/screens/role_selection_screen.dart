import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/auth_header_widget.dart';
import '../../../../core/widgets/auth_language_toggle_widget.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/role_option_card_widget.dart';

/// First screen of the auth flow: the user picks whether they are
/// signing up/in as a customer or as a driver before reaching the sign
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
    // Centered with a width cap on wide screens, and scrollable so a large
    // text size or a short screen never overflows; on a normal phone the
    // content still fills the height, with the button at the bottom.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingXXL),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - AppConstants.paddingXXL * 2,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AuthLanguageToggleWidget(),
                        ),
                        const Spacer(),
                        AuthHeaderWidget(
                          title: context.l10n.welcomeToApp,
                          subtitle: context.l10n.chooseAccountType,
                        ),
                        const SizedBox(height: AppConstants.paddingXXL),
                        RoleOptionCardWidget(
                          role: UserRole.customer,
                          icon: Icons.person_rounded,
                          isSelected: _selected == UserRole.customer,
                          onTap: () =>
                              setState(() => _selected = UserRole.customer),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        RoleOptionCardWidget(
                          role: UserRole.driver,
                          icon: Icons.local_taxi_rounded,
                          isSelected: _selected == UserRole.driver,
                          onTap: () =>
                              setState(() => _selected = UserRole.driver),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppConstants.paddingXXL),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
