import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/validators/phone_input_formatter.dart';
import '../../../../core/widgets/app_choice_chip_widget.dart';
import '../../../../core/widgets/auth_form_layout_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../../../../core/widgets/auth_footer_link_widget.dart';
import '../../data/models/driver_signup_request_model.dart';
import '../cubit/driver_signup_cubit.dart';
import '../cubit/driver_signup_state.dart';
import '../widgets/signup_photo_tile_widget.dart';

/// A driver creates his own account and car, with two photos. The account is
/// pending until a manager approves it, so success leads to a "waiting for
/// approval" screen, never to the home screen.
class DriverSignUpScreen extends StatelessWidget {
  const DriverSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverSignupCubit>(
      create: (_) => sl<DriverSignupCubit>()..loadVehicleTypes(),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _phone, _password, _address,
      _brand, _model, _color, _plate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    // The form's own checks first; the car type and photos are checked by
    // the cubit, which then shows what is missing.
    final valid = _formKey.currentState!.validate();
    final cubit = context.read<DriverSignupCubit>();
    if (!valid) {
      cubit.showMissingChoices();
      return;
    }
    cubit.submit((
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      address: _address.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      color: _color.text.trim(),
      plateNumber: _plate.text.trim(),
    ));
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty
      ? context.l10n.driverSignupFieldRequired
      : null;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverSignupCubit, DriverSignupState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == DriverSignupStatus.success,
      listener: (context, state) => Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.driverSignupPending,
        (route) => false,
      ),
      builder: (context, state) {
        final l10n = context.l10n;
        final cubit = context.read<DriverSignupCubit>();
        return AuthFormLayoutWidget(
          formKey: _formKey,
          title: l10n.driverSignupTitle,
          subtitle: l10n.driverSignupSubtitle,
          role: UserRole.driver,
          onChangeRole: () =>
              Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection),
          fields: [
            AuthTextFieldWidget(
              controller: _firstName,
              label: l10n.firstNameLabel,
              hint: l10n.firstNameHint,
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              validator: AuthValidators.name,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _lastName,
              label: l10n.lastNameLabel,
              hint: l10n.lastNameHint,
              prefixIcon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              validator: AuthValidators.name,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _phone,
              label: l10n.phoneNumber,
              hint: '09xxxxxxxx',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: const [PhoneInputFormatter()],
              forceLtr: true,
              validator: AuthValidators.phone,
              serverError: state.phoneError,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _password,
              label: l10n.password,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              autofillHints: const [AutofillHints.newPassword],
              forceLtr: true,
              validator: AuthValidators.signupPassword,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _address,
              label: l10n.driverSignupAddressLabel,
              hint: '',
              prefixIcon: Icons.home_outlined,
              validator: (_) => null,
              maxLength: 255,
              enabled: !state.isSubmitting,
            ),
            SignupPhotoTileWidget(
              label: l10n.driverSignupPhotoPerson,
              icon: Icons.account_circle_outlined,
              photoPath: state.photoPath,
              error: state.photoError ??
                  (state.photoMissing ? l10n.driverSignupPhotoRequired : null),
              onPick: cubit.pickPhoto,
            ),
            _SectionTitle(l10n.driverSignupCarSection),
            if (state.isLoadingTypes)
              const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            else if (state.typesError != null)
              Column(
                children: [
                  Text(
                    state.typesError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(onPressed: cubit.loadVehicleTypes, child: Text(l10n.retry)),
                ],
              )
            else
              _ChoiceGroup(
                title: l10n.driverSignupVehicleType,
                error: state.vehicleTypeMissing ? l10n.driverSignupChooseOne : null,
                choices: [
                  for (final type in state.vehicleTypes)
                    (
                      label: type.name,
                      selected: state.vehicleTypeId == type.id,
                      onTap: () => cubit.selectVehicleType(type.id),
                    ),
                ],
              ),
            AuthTextFieldWidget(
              controller: _brand,
              label: l10n.driverSignupBrandLabel,
              hint: l10n.driverSignupBrandHint,
              prefixIcon: Icons.directions_car_outlined,
              textCapitalization: TextCapitalization.words,
              validator: _required,
              maxLength: 50,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _model,
              label: l10n.driverSignupModelLabel,
              hint: l10n.driverSignupModelHint,
              prefixIcon: Icons.directions_car_filled_outlined,
              textCapitalization: TextCapitalization.words,
              validator: _required,
              maxLength: 50,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _color,
              label: l10n.driverSignupColorLabel,
              hint: l10n.driverSignupColorHint,
              prefixIcon: Icons.palette_outlined,
              validator: _required,
              maxLength: 30,
              enabled: !state.isSubmitting,
            ),
            AuthTextFieldWidget(
              controller: _plate,
              label: l10n.driverSignupPlateLabel,
              hint: l10n.driverSignupPlateHint,
              prefixIcon: Icons.pin_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              forceLtr: true,
              validator: (value) {
                final text = (value ?? '').trim();
                return text.length < 2 || text.length > 20
                    ? l10n.driverSignupFieldRequired
                    : null;
              },
              serverError: state.plateError,
              maxLength: 20,
              enabled: !state.isSubmitting,
            ),
            _ChoiceGroup(
              title: l10n.driverSignupOwnership,
              error: null,
              choices: [
                (
                  label: l10n.driverSignupOwnershipOwner,
                  selected: state.ownership == VehicleOwnership.owner,
                  onTap: () => cubit.selectOwnership(VehicleOwnership.owner),
                ),
                (
                  label: l10n.driverSignupOwnershipCompany,
                  selected: state.ownership == VehicleOwnership.company,
                  onTap: () => cubit.selectOwnership(VehicleOwnership.company),
                ),
              ],
            ),
            SignupPhotoTileWidget(
              label: l10n.driverSignupPhotoCar,
              icon: Icons.directions_car_outlined,
              photoPath: state.vehiclePhotoPath,
              error: state.vehiclePhotoError ??
                  (state.vehiclePhotoMissing ? l10n.driverSignupPhotoRequired : null),
              onPick: cubit.pickVehiclePhoto,
            ),
          ],
          errorMessage: state.errorMessage,
          submitLabel: l10n.signUp,
          isSubmitting: state.isSubmitting,
          onSubmit: _submit,
          footer: AuthFooterLinkWidget(
            text: l10n.hasAccount,
            actionLabel: l10n.signIn,
            onTap: () => Navigator.of(context).pushReplacementNamed(AppRouter.driverSignIn),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppConstants.paddingS),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

typedef _Choice = ({String label, bool selected, VoidCallback onTap});

/// A title and a row of pills of which one is chosen.
class _ChoiceGroup extends StatelessWidget {
  final String title;
  final String? error;
  final List<_Choice> choices;

  const _ChoiceGroup({required this.title, required this.error, required this.choices});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: AppConstants.paddingS),
        Wrap(
          spacing: AppConstants.paddingS,
          runSpacing: AppConstants.paddingS,
          children: [
            for (final choice in choices)
              AppChoiceChipWidget(
                label: choice.label,
                selected: choice.selected,
                onSelected: (_) => choice.onTap(),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingXS),
            child: Text(error!, style: textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ),
      ],
    );
  }
}
