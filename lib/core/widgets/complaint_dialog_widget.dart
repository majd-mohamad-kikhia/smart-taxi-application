import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../complaints/complaint_cubit.dart';
import '../complaints/complaint_state.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';
import 'app_animated_dialog.dart';
import 'auth_primary_button_widget.dart';

/// Opens the app's shared [showAppDialog] shell with a complaint form as
/// its content, reporting success back through [onSubmitted] once the
/// complaint reaches the server. [createCubit] supplies the role-specific
/// [ComplaintCubit].
Future<void> showComplaintDialog(
  BuildContext context, {
  required ComplaintCubit Function() createCubit,
  required VoidCallback onSubmitted,
}) {
  return showAppDialog<void>(
    context: context,
    title: context.l10n.complaintSend,
    icon: Icons.report_gmailerrorred_rounded,
    tone: AppDialogTone.warning,
    // A stray tap outside (or the back button) must not throw away a typed
    // complaint or close the dialog mid-request; Cancel is in the form.
    barrierDismissible: false,
    showActions: false,
    content: BlocProvider<ComplaintCubit>(
      create: (_) => createCubit(),
      child: _ComplaintFormWidget(onSubmitted: onSubmitted),
    ),
  );
}

/// Form fields + actions rendered inside the shared dialog shell's
/// [content] slot.
class _ComplaintFormWidget extends StatefulWidget {
  final VoidCallback onSubmitted;

  const _ComplaintFormWidget({required this.onSubmitted});

  @override
  State<_ComplaintFormWidget> createState() => _ComplaintFormWidgetState();
}

class _ComplaintFormWidgetState extends State<_ComplaintFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ComplaintCubit>().submit(
      message: _messageController.text.trim(),
      subject: _subjectController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ComplaintCubit, ComplaintState>(
      listener: (context, state) {
        if (state.submitStatus == ComplaintSubmitStatus.success) {
          Navigator.of(context).pop();
          widget.onSubmitted();
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final isSubmitting =
            state.submitStatus == ComplaintSubmitStatus.submitting;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                enabled: !isSubmitting,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: l10n.complaintSubjectLabel,
                  hintText: l10n.complaintSubjectHint,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _messageController,
                enabled: !isSubmitting,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: l10n.complaintDetailsLabel,
                  hintText: l10n.complaintDetailsHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 5) return l10n.complaintMinLength;
                  if (text.length > 1000) return l10n.complaintMaxLength;
                  return null;
                },
              ),
              if (state.submitStatus == ComplaintSubmitStatus.failure) ...[
                const SizedBox(height: 4),
                Text(
                  state.errorMessage ?? l10n.complaintSendFailed,
                  style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuthPrimaryButtonWidget(
                      label: l10n.send,
                      isLoading: isSubmitting,
                      onPressed: () => _submit(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
