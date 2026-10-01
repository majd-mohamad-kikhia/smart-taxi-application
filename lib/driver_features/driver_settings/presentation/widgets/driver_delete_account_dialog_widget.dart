import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_destructive_button_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../cubit/driver_account_deletion_cubit.dart';
import '../cubit/driver_account_deletion_state.dart';

/// Opens the shared dialog shell with the driver's "delete my account"
/// request form: an explanation, the password, an optional reason, and a
/// destructive send button. The dialog closes itself once the request is
/// sent; the status card behind it then shows "under review".
Future<void> showDriverDeleteAccountDialog(
  BuildContext context, {
  required DriverAccountDeletionCubit cubit,
}) {
  final l10n = context.l10n;
  return showAppDialog<void>(
    context: context,
    title: l10n.deleteAccountTitle,
    message: l10n.driverDeleteMessage,
    icon: Icons.delete_forever_rounded,
    tone: AppDialogTone.destructive,
    showActions: false,
    // Closing the dialog mid-request would leave it running unseen.
    barrierDismissible: false,
    content: BlocProvider<DriverAccountDeletionCubit>.value(
      value: cubit,
      child: const _DriverDeleteAccountFormWidget(),
    ),
  );
}

class _DriverDeleteAccountFormWidget extends StatefulWidget {
  const _DriverDeleteAccountFormWidget();

  @override
  State<_DriverDeleteAccountFormWidget> createState() =>
      _DriverDeleteAccountFormWidgetState();
}

class _DriverDeleteAccountFormWidgetState
    extends State<_DriverDeleteAccountFormWidget> {
  static const int _maxReasonLength = 500;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<DriverAccountDeletionCubit>().submit(
      _passwordController.text,
      _reasonController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverAccountDeletionCubit, DriverAccountDeletionState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting &&
          !current.isSubmitting &&
          current.submitError == null,
      listener: (context, state) => Navigator.of(context).pop(),
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting ||
          previous.submitError != current.submitError,
      builder: (context, state) {
        final l10n = context.l10n;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextFieldWidget(
                controller: _passwordController,
                label: l10n.deleteAccountPasswordLabel,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: AuthValidators.loginPassword,
              ),
              const SizedBox(height: 12),
              AuthTextFieldWidget(
                controller: _reasonController,
                label: l10n.driverDeleteReasonLabel,
                hint: l10n.driverDeleteReasonHint,
                prefixIcon: Icons.edit_note_rounded,
                textInputAction: TextInputAction.done,
                maxLength: _maxReasonLength,
                validator: (_) => null,
              ),
              if (state.submitError != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.submitError!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              AppDestructiveButtonWidget(
                label: l10n.driverDeleteSubmit,
                isLoading: state.isSubmitting,
                onPressed: () => _submit(context),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
