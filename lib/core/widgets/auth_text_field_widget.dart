import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';

/// Labeled text field with the auth screens' shared styling, including
/// an optional show/hide toggle for password fields.
///
/// - [onSubmitted] runs when the keyboard's action key is pressed on the
///   last field, so Done submits the form.
/// - [autofillHints] lets the keyboard and password managers fill the field
///   (wrap the fields in an `AutofillGroup`).
/// - [forceLtr] keeps a phone number or password in left-to-right order
///   inside Arabic text, sitting at the start edge of the field.
class AuthTextFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;

  /// Caps the input length (and shows the counter) when set.
  final int? maxLength;

  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool forceLtr;

  /// `false` locks the field (for example while a save is running).
  final bool enabled;

  /// A problem the server reported for this field after a submit (for
  /// example "phone already in use"), shown under the field until the
  /// field's own validation has something to say.
  final String? serverError;

  const AuthTextFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.onSubmitted,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.forceLtr = false,
    this.enabled = true,
    this.serverError,
  });

  @override
  State<AuthTextFieldWidget> createState() => _AuthTextFieldWidgetState();
}

class _AuthTextFieldWidgetState extends State<AuthTextFieldWidget> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    // A left-to-right value in an Arabic screen still sits at the field's
    // start edge (the right), as the label and hint do.
    final isRtlScreen = Directionality.of(context) == TextDirection.rtl;
    final ltrAlign = isRtlScreen ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppConstants.paddingS),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.isPassword && _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          textDirection: widget.forceLtr ? TextDirection.ltr : null,
          textAlign: widget.forceLtr ? ltrAlign : TextAlign.start,
          onFieldSubmitted: widget.onSubmitted == null
              ? null
              : (_) => widget.onSubmitted!(),
          validator: widget.validator,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintTextDirection: widget.forceLtr ? TextDirection.ltr : null,
            errorText: widget.serverError,
            prefixIcon: Icon(widget.prefixIcon),
            // Validation messages (often long in Arabic) wrap instead of
            // being cut off after one line.
            errorMaxLines: 3,
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscured
                        ? context.l10n.showPassword
                        : context.l10n.hidePassword,
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
