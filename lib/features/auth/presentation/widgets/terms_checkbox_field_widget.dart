import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// "I agree to the Terms and conditions" checkbox for the sign-up form.
/// It is a [FormField], so the form's `validate()` fails — and shows the
/// error under the checkbox — until it is ticked. The coloured
/// "Terms and conditions" text opens the terms via [onOpenTerms].
class TermsCheckboxFieldWidget extends StatefulWidget {
  final VoidCallback onOpenTerms;

  const TermsCheckboxFieldWidget({super.key, required this.onOpenTerms});

  @override
  State<TermsCheckboxFieldWidget> createState() => _TermsCheckboxFieldWidgetState();
}

class _TermsCheckboxFieldWidgetState extends State<TermsCheckboxFieldWidget> {
  late final TapGestureRecognizer _linkTap;

  @override
  void initState() {
    super.initState();
    _linkTap = TapGestureRecognizer()..onTap = widget.onOpenTerms;
  }

  @override
  void dispose() {
    _linkTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormField<bool>(
      initialValue: false,
      validator: (accepted) => accepted == true ? null : l10n.termsRequired,
      builder: (field) {
        final accepted = field.value == true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => field.didChange(!accepted),
              child: Row(
                children: [
                  Checkbox(
                    value: accepted,
                    onChanged: (value) => field.didChange(value ?? false),
                    activeColor: AppColors.primary,
                    checkColor: AppColors.textOnPrimary,
                    side: BorderSide(
                      color: field.hasError ? AppColors.error : AppColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: l10n.termsAgreePrefix,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.termsAndConditions,
                            recognizer: _linkTap,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLink,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textLink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
