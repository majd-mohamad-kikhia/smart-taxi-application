import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../enums/user_role.dart';
import 'auth_error_banner_widget.dart';
import 'auth_header_widget.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingXXL),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingL),
                AuthHeaderWidget(title: title, subtitle: subtitle),
                const SizedBox(height: AppConstants.paddingL),
                if (role != null)
                  Center(
                    child: RoleBadgeWidget(role: role!, onChange: onChangeRole),
                  ),
                const SizedBox(height: AppConstants.paddingXXL),
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
                if (footer != null) ...[
                  const SizedBox(height: AppConstants.paddingXL),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
