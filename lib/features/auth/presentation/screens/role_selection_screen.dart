
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../../../core/widgets/auth_brand_header_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
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
    final l10n = context.l10n;
    // The green brand header on top with the two role cards in one white
    // card riding up over its edge, and Continue at the bottom. Scrollable
    // so a large text size or a short screen never overflows; on a normal
    // phone the content still fills the height, with the button at the
    // bottom.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(Brightness.dark),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandHeaderWidget(
                    title: l10n.welcomeToApp,
                    subtitle: l10n.chooseAccountType,
                    overlap: _cardOverlap,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Transform.translate(
                          offset: const Offset(0, -_cardOverlap),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppConstants.paddingXL,
                              0,
                              AppConstants.paddingXL,
                              MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusXL,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.colors.shadowMedium,
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: AppSurfaceCardWidget(
                                    radius: AppConstants.radiusXL,
                                    padding: const EdgeInsets.all(
                                      AppConstants.paddingL,
                                    ),
                                    child: Column(
                                      children: [
                                        RoleOptionCardWidget(
                                          role: UserRole.customer,
                                          icon: Icons.person_rounded,
                                          isSelected:
                                              _selected == UserRole.customer,
                                          onTap: () => setState(
                                            () => _selected = UserRole.customer,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppConstants.paddingM,
                                        ),
                                        RoleOptionCardWidget(
                                          role: UserRole.driver,
                                          icon: Icons.local_taxi_rounded,
                                          isSelected:
                                              _selected == UserRole.driver,
                                          onTap: () => setState(
                                            () => _selected = UserRole.driver,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: AppConstants.paddingXXL),
                                AuthPrimaryButtonWidget(
                                  label: l10n.continueLabel,
                                  isLoading: false,
                                  onPressed: _selected == null ? null : _continue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// How far the role card overlaps the green header.
  static const double _cardOverlap = 48;
}
