import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/widgets/auth_form_layout_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_footer_link_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthCubit get _cubit => sl<AuthCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = _cubit.state.selectedRole;
      if (role == null) {
        Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
      } else if (role == UserRole.driver) {
        // Drivers don't self-register — only riders can sign up.
        Navigator.of(context).pushReplacementNamed(AppRouter.driverSignIn);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _cubit.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _changeRole() {
    _cubit.resetStatus();
    Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
  }

  void _goToSignIn() {
    _cubit.resetStatus();
    Navigator.of(context).pushReplacementNamed(AppRouter.signIn);
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: _cubit,
      listener: _onStateChanged,
      builder: (context, state) {
        return AuthFormLayoutWidget(
          formKey: _formKey,
          title: 'إنشاء حساب',
          subtitle: 'أدخل بياناتك لإنشاء حساب جديد في مشوار',
          role: state.selectedRole,
          onChangeRole: _changeRole,
          fields: [
            AuthTextFieldWidget(
              controller: _firstNameController,
              label: 'الاسم',
              hint: 'مثال: محمد',
              prefixIcon: Icons.person_outline,
              validator: AuthValidators.name,
            ),
            AuthTextFieldWidget(
              controller: _lastNameController,
              label: 'الكنية',
              hint: 'مثال: العتيبي',
              prefixIcon: Icons.badge_outlined,
              validator: AuthValidators.name,
            ),
            AuthTextFieldWidget(
              controller: _phoneController,
              label: 'رقم الجوال',
              hint: '05xxxxxxxx',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: AuthValidators.phone,
            ),
            AuthTextFieldWidget(
              controller: _passwordController,
              label: 'كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: AuthValidators.signupPassword,
            ),
            AuthTextFieldWidget(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
            ),
          ],
          errorMessage: state.status == AuthStatus.failure
              ? state.errorMessage
              : null,
          submitLabel: 'إنشاء حساب',
          isSubmitting: state.status == AuthStatus.submitting,
          onSubmit: _submit,
          footer: AuthFooterLinkWidget(
            text: 'لديك حساب بالفعل؟',
            actionLabel: 'تسجيل الدخول',
            onTap: _goToSignIn,
          ),
        );
      },
    );
  }
}
