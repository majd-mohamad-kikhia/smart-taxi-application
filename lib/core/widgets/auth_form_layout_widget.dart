import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../enums/user_role.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'app_surface_card_widget.dart';
import 'auth_error_banner_widget.dart';
import 'auth_brand_header_widget.dart';
import 'auth_primary_button_widget.dart';
import 'role_badge_widget.dart';

/// Shared scaffold for any sign in / sign up screen (customer or driver):
/// header, optional role badge, the screen's own fields, an optional
/// error banner, the submit button, and an optional footer link.
///
/// Every auth screen in the app is otherwise an identical wrapper around
/// this layout, so this is the one place their shared spacing/structure
/// lives.
class AuthFormLayoutWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final UserRole? role;
  final VoidCallback onChangeRole;
  final List<Widget> fields;
  final String? errorMessage;
  final String submitLabel;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Widget? footer;

  const AuthFormLayoutWidget({
    super.key,
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.onChangeRole,
    required this.fields,
    required this.errorMessage,
    required this.submitLabel,
    required this.isSubmitting,
    required this.onSubmit,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // White status bar icons over the green header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(Brightness.dark),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            // Lets the keyboard and password managers fill the whole form
            // and offer to save the sign-in.
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandHeaderWidget(
                    title: title,
                    subtitle: subtitle,
                    overlap: _cardOverlap,
                    below: role == null
                        ? null
                        : RoleBadgeWidget(role: role!, onChange: onChangeRole),
                  ),
                  // The form card rides up over the header's bottom edge.
                  Transform.translate(
                    offset: const Offset(0, -_cardOverlap),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingXL,
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
                              padding: const EdgeInsets.all(AppConstants.paddingXL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < fields.length; i++) ...[
                                    fields[i],
                                    SizedBox(
                                      height: i == fields.length - 1
                                          ? AppConstants.paddingXL
                                          : AppConstants.paddingL,
                                    ),
                                  ],
                                  if (errorMessage != null) ...[
                                    AuthErrorBannerWidget(message: errorMessage!),
                                    const SizedBox(height: AppConstants.paddingM),
                                  ],
                                  AuthPrimaryButtonWidget(
                                    label: submitLabel,
                                    isLoading: isSubmitting,
                                    onPressed: onSubmit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (footer != null) ...[
                            const SizedBox(height: AppConstants.paddingXL),
                            footer!,
                          ],
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom +
                                AppConstants.paddingL,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// How far the form card overlaps the green header.
  static const double _cardOverlap = 48;
}
