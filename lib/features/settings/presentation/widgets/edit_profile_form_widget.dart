import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/validators/phone_input_formatter.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../../data/models/customer_profile_model.dart';

/// Owns the edit form's controllers and exposes the trimmed values
/// through [onSubmit] once validation passes.
///
/// It reports through [onDirtyChanged] whether anything differs from the
/// saved profile, so the screen can enable Save only then and ask before
/// leaving with unsaved edits. A problem the server reported for one field
/// ([serverErrors], by the API's field name) is shown under that field and
/// goes away as soon as the field is edited. While [isSaving] the fields are
/// locked.
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
  final ValueChanged<bool> onDirtyChanged;
  final Widget submitButton;
  final Widget? banner;
  final Map<String, String> serverErrors;
  final bool isSaving;

  const EditProfileFormWidget({
    super.key,
    required this.profile,
    required this.onSubmit,
    required this.onDirtyChanged,
    required this.submitButton,
    this.banner,
    this.serverErrors = const {},
    this.isSaving = false,
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

  /// Fields whose server error has been dismissed by editing them.
  final Set<String> _editedSinceError = {};
  bool _wasDirty = false;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final Map<String, TextEditingController> _byApiField = {
    'first_name': _firstName,
    'last_name': _lastName,
    'phone_number': _phone,
    'email': _email,
    'address': _address,
  };

  @override
  void initState() {
    super.initState();
    for (final entry in _byApiField.entries) {
      entry.value.addListener(() {
        _editedSinceError.add(entry.key);
        _notifyDirty();
      });
    }
  }

  @override
  void didUpdateWidget(covariant EditProfileFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new set of server errors is fresh again.
    if (oldWidget.serverErrors != widget.serverErrors) {
      _editedSinceError.clear();
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _firstName.text.trim() != widget.profile.firstName ||
      _lastName.text.trim() != widget.profile.lastName ||
      _phone.text.trim() != widget.profile.phone ||
      _email.text.trim() != (widget.profile.email ?? '') ||
      _address.text.trim() != (widget.profile.address ?? '');

  void _notifyDirty() {
    final dirty = _isDirty;
    if (dirty != _wasDirty) {
      _wasDirty = dirty;
      widget.onDirtyChanged(dirty);
    }
    // The shown server errors depend on which fields were edited.
    if (mounted) setState(() {});
  }

  String? _serverError(String apiField) => _editedSinceError.contains(apiField)
      ? null
      : widget.serverErrors[apiField];

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
    final enabled = !widget.isSaving;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            AuthTextFieldWidget(
              controller: _firstName,
              label: l10n.fieldFirstName,
              hint: l10n.firstNameEditHint,
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              enabled: enabled,
              serverError: _serverError('first_name'),
              validator: AuthValidators.name,
            ),
            const SizedBox(height: AppConstants.paddingL),
            AuthTextFieldWidget(
              controller: _lastName,
              label: l10n.familyNameLabel,
              hint: l10n.familyNameHint,
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              enabled: enabled,
              serverError: _serverError('last_name'),
              validator: AuthValidators.name,
            ),
            const SizedBox(height: AppConstants.paddingL),
            AuthTextFieldWidget(
              controller: _phone,
              label: l10n.phoneNumber,
              hint: l10n.phoneEditHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: const [PhoneInputFormatter()],
              forceLtr: true,
              enabled: enabled,
              serverError: _serverError('phone_number'),
              validator: AuthValidators.phone,
            ),
            const SizedBox(height: AppConstants.paddingL),
            AuthTextFieldWidget(
              controller: _email,
              label: l10n.emailOptionalLabel,
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              forceLtr: true,
              enabled: enabled,
              serverError: _serverError('email'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty || _emailRegExp.hasMatch(text)) return null;
                return l10n.valEmailInvalid;
              },
            ),
            const SizedBox(height: AppConstants.paddingL),
            AuthTextFieldWidget(
              controller: _address,
              label: l10n.addressOptionalLabel,
              hint: l10n.addressHint,
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: _isDirty ? submit : null,
              autofillHints: const [AutofillHints.fullStreetAddress],
              enabled: enabled,
              serverError: _serverError('address'),
              validator: (_) => null,
            ),
            if (widget.banner != null) ...[
              const SizedBox(height: AppConstants.paddingL),
              widget.banner!,
            ],
            const SizedBox(height: AppConstants.paddingXXL),
            widget.submitButton,
          ],
        ),
      ),
    );
  }
}
