import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/validators/phone_input_formatter.dart';
import '../../../../core/widgets/auth_form_layout_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../cubit/driver_auth_cubit.dart';
import '../cubit/driver_auth_state.dart';

/// Driver sign in — drivers don't self-register in this app (onboarding
/// happens another way), so there is no matching sign-up screen or
/// footer link here.
class DriverSignInScreen extends StatefulWidget {
  const DriverSignInScreen({super.key});

  @override
  State<DriverSignInScreen> createState() => _DriverSignInScreenState();
}

class _DriverSignInScreenState extends State<DriverSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  DriverAuthCubit get _cubit => sl<DriverAuthCubit>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _cubit.signIn(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _changeRole() {
    _cubit.resetStatus();
    Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
  }

  void _onStateChanged(BuildContext context, DriverAuthState state) {
    if (state.status == DriverAuthStatus.success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.driverHome,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverAuthCubit, DriverAuthState>(
      bloc: _cubit,
      listener: _onStateChanged,
      builder: (context, state) {
        final l10n = context.l10n;
        return AuthFormLayoutWidget(
          formKey: _formKey,
          title: l10n.driverSignInTitle,
          subtitle: l10n.signInSubtitle,
          role: UserRole.driver,
          onChangeRole: _changeRole,
          fields: [
            AuthTextFieldWidget(
              controller: _phoneController,
              label: l10n.phoneNumber,
              hint: '09xxxxxxxx',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.username],
              inputFormatters: const [PhoneInputFormatter()],
              forceLtr: true,
              validator: AuthValidators.phone,
            ),
            AuthTextFieldWidget(
              controller: _passwordController,
              label: l10n.password,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              autofillHints: const [AutofillHints.password],
              forceLtr: true,
              validator: AuthValidators.loginPassword,
            ),
          ],
          errorMessage: state.status == DriverAuthStatus.failure
              ? state.errorMessage
              : null,
          submitLabel: l10n.signIn,
          isSubmitting: state.status == DriverAuthStatus.submitting,
          onSubmit: _submit,
        );
      },
    );
  }
}
