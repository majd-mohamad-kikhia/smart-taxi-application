import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/validators/phone_input_formatter.dart';
import '../../../../core/widgets/auth_form_layout_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/widgets/auth_footer_link_widget.dart';

/// Customer sign in — drivers use `driver_features/driver_auth`'s own screen,
/// since they don't share a sign-up flow or account shape.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthCubit get _cubit => sl<AuthCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_cubit.state.selectedRole == null) {
        Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
      }
    });
  }

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

  void _goToSignUp() {
    _cubit.resetStatus();
    Navigator.of(context).pushReplacementNamed(AppRouter.signUp);
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.success) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: _cubit,
      listener: _onStateChanged,
      builder: (context, state) {
        final l10n = context.l10n;
        return AuthFormLayoutWidget(
          formKey: _formKey,
          title: l10n.signIn,
          subtitle: l10n.signInSubtitle,
          role: state.selectedRole,
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
            // No reset endpoint exists for customers, so a forgotten
            // password is handled by support.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRouter.contactUs,
                  arguments: UserRole.customer,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textLink,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: Text(l10n.forgotPasswordContactSupport),
              ),
            ),
          ],
          errorMessage:
              state.status == AuthStatus.failure ? state.errorMessage : null,
          submitLabel: l10n.signIn,
          isSubmitting: state.status == AuthStatus.submitting,
          onSubmit: _submit,
          footer: AuthFooterLinkWidget(
            text: l10n.noAccount,
            actionLabel: l10n.signUp,
            onTap: _goToSignUp,
          ),
        );
      },
    );
  }
}
