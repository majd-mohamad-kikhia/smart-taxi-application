import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../../data/models/customer_profile_model.dart';

/// Owns the edit form's controllers and exposes the trimmed values
/// through [onSubmit] once validation passes.
class EditProfileFormWidget extends StatefulWidget {
  final CustomerProfileModel profile;
  final void Function({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String address,
  })
  onSubmit;
  final Widget submitButton;
  final Widget? banner;

  const EditProfileFormWidget({
    super.key,
    required this.profile,
    required this.onSubmit,
    required this.submitButton,
    this.banner,
  });

  @override
  State<EditProfileFormWidget> createState() => EditProfileFormWidgetState();
}

class EditProfileFormWidgetState extends State<EditProfileFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _email = TextEditingController(text: widget.profile.email ?? '');
  late final _address = TextEditingController(
    text: widget.profile.address ?? '',
  );

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextFieldWidget(
            controller: _firstName,
            label: l10n.fieldFirstName,
            hint: l10n.firstNameEditHint,
            prefixIcon: Icons.person_outline,
            validator: AuthValidators.name,
          ),
          const SizedBox(height: 16),
          AuthTextFieldWidget(
            controller: _lastName,
            label: l10n.familyNameLabel,
            hint: l10n.familyNameHint,
            prefixIcon: Icons.person_outline,
            validator: AuthValidators.name,
          ),
          const SizedBox(height: 16),
          AuthTextFieldWidget(
            controller: _phone,
            label: l10n.phoneNumber,
            hint: l10n.phoneEditHint,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: AuthValidators.phone,
          ),
          const SizedBox(height: 16),
          AuthTextFieldWidget(
            controller: _email,
            label: l10n.emailOptionalLabel,
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty || _emailRegExp.hasMatch(text)) return null;
              return l10n.valEmailInvalid;
            },
          ),
          const SizedBox(height: 16),
          AuthTextFieldWidget(
            controller: _address,
            label: l10n.addressOptionalLabel,
            hint: l10n.addressHint,
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
            validator: (_) => null,
          ),
          if (widget.banner != null) ...[
            const SizedBox(height: 16),
            widget.banner!,
          ],
          const SizedBox(height: 24),
          widget.submitButton,
        ],
      ),
    );
  }
}
