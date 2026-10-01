import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';

/// Opens the shared dialog shell with the "delete my account" form:
/// a warning, the password field, Cancel and a destructive confirm button.
/// [onDeleted] runs once the server has deleted the account and this
/// device is signed out. [createCubit] supplies the [DeleteAccountCubit].
Future<void> showDeleteAccountDialog(
  BuildContext context, {
  required DeleteAccountCubit Function() createCubit,
  required VoidCallback onDeleted,
}) {
  final l10n = context.l10n;
  return showAppDialog<void>(
    context: context,
    title: l10n.deleteAccountTitle,
    message: l10n.deleteAccountMessage,
    icon: Icons.delete_forever_rounded,
    tone: AppDialogTone.destructive,
    showActions: false,
    // Closing the dialog mid-request would leave it running unseen.
    barrierDismissible: false,
    content: BlocProvider<DeleteAccountCubit>(
      create: (_) => createCubit(),
      child: _DeleteAccountFormWidget(onDeleted: onDeleted),
    ),
  );
}

class _DeleteAccountFormWidget extends StatefulWidget {
  final VoidCallback onDeleted;

  const _DeleteAccountFormWidget({required this.onDeleted});

  @override
  State<_DeleteAccountFormWidget> createState() =>
      _DeleteAccountFormWidgetState();
}

class _DeleteAccountFormWidgetState extends State<_DeleteAccountFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<DeleteAccountCubit>().submit(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state.status == DeleteAccountStatus.success) {
          Navigator.of(context).pop();
          widget.onDeleted();
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextFieldWidget(
                controller: _passwordController,
                label: l10n.deleteAccountPasswordLabel,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: () => _submit(context),
                forceLtr: true,
                enabled: !state.isSubmitting,
                autofillHints: const [AutofillHints.password],
                validator: AuthValidators.loginPassword,
              ),
              if (state.status == DeleteAccountStatus.failure &&
                  state.errorMessage != null) ...[
                const SizedBox(height: AppConstants.paddingS),
                AuthErrorBannerWidget(message: state.errorMessage!),
              ],
              const SizedBox(height: AppConstants.paddingL),
              // The safe way out first, the permanent action second, and the
              // permanent one is available only once a password is typed.
              AppNeutralButtonWidget(
                label: l10n.cancel,
                onPressed: state.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppConstants.paddingM),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (context, value, _) => AppDestructiveButtonWidget(
                  label: l10n.deleteAccountConfirm,
                  isLoading: state.isSubmitting,
                  onPressed: value.text.isEmpty ? null : () => _submit(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
