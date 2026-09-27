import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../cubit/driver_complaint_cubit.dart';
import '../cubit/driver_complaint_state.dart';

/// Opens the app's shared [showAppDialog] shell with a complaint form as
/// its content, reporting success back through [onSubmitted] once the
/// driver's complaint reaches the server.
Future<void> showComplaintDialog(
  BuildContext context, {
  required VoidCallback onSubmitted,
}) {
  return showAppDialog<void>(
    context: context,
    title: 'إرسال بلاغ',
    icon: Icons.report_gmailerrorred_rounded,
    tone: AppDialogTone.warning,
    showActions: false,
    content: BlocProvider<DriverComplaintCubit>(
      create: (_) => sl<DriverComplaintCubit>(),
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
    context.read<DriverComplaintCubit>().submit(
          message: _messageController.text.trim(),
          subject: _subjectController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverComplaintCubit, DriverComplaintState>(
      listener: (context, state) {
        if (state.submitStatus == ComplaintSubmitStatus.success) {
          Navigator.of(context).pop();
          widget.onSubmitted();
        }
      },
      builder: (context, state) {
        final isSubmitting = state.submitStatus == ComplaintSubmitStatus.submitting;
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
                decoration: const InputDecoration(
                  labelText: 'الموضوع (اختياري)',
                  hintText: 'عنوان مختصر للبلاغ',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _messageController,
                enabled: !isSubmitting,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'التفاصيل',
                  hintText: 'اكتب تفاصيل البلاغ هنا...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 5) return 'يرجى كتابة 5 أحرف على الأقل';
                  if (text.length > 1000) return 'الحد الأقصى 1000 حرف';
                  return null;
                },
              ),
              if (state.submitStatus == ComplaintSubmitStatus.failure) ...[
                const SizedBox(height: 4),
                Text(
                  state.errorMessage ?? 'تعذر إرسال البلاغ',
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuthPrimaryButtonWidget(
                      label: 'إرسال',
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
