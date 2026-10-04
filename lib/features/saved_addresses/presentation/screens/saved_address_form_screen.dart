import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/presentation/saved_address_type_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/auth_text_field_widget.dart';
import '../../../../core/widgets/location_select_button_widget.dart';
import '../cubit/saved_address_form_cubit.dart';
import '../cubit/saved_address_form_state.dart';

/// Adds or edits one saved place: the map pin (with address and address
/// details, from the location picker) and, for an "other" place, its name.
/// Pops with `replaced` (true when an older home / work was replaced).
class SavedAddressFormScreen extends StatelessWidget {
  final SavedAddressType type;
  final SavedAddressModel? existing;

  const SavedAddressFormScreen({super.key, required this.type, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavedAddressFormCubit>(
      create: (_) => sl<SavedAddressFormCubit>(param1: type, param2: existing),
      child: _SavedAddressFormView(type: type, existing: existing),
    );
  }
}

class _SavedAddressFormView extends StatefulWidget {
  final SavedAddressType type;
  final SavedAddressModel? existing;

  const _SavedAddressFormView({required this.type, this.existing});

  @override
  State<_SavedAddressFormView> createState() => _SavedAddressFormViewState();
}

class _SavedAddressFormViewState extends State<_SavedAddressFormView> {
  static const _maxLabelLength = 50;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController =
      TextEditingController(text: widget.existing?.label ?? '');

  bool get _needsLabel => widget.type == SavedAddressType.other;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typeName = widget.type.name(l10n);
    final title = widget.existing == null
        ? l10n.savedAddressAddTitle(typeName)
        : l10n.savedAddressEditTitle(widget.existing!.title(l10n));

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: Text(title)),
      body: BlocConsumer<SavedAddressFormCubit, SavedAddressFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == SavedAddressFormStatus.saved,
        listener: (context, state) => Navigator.of(context).pop(state.replaced),
        builder: (context, state) {
          final cubit = context.read<SavedAddressFormCubit>();
          final locationError = [
            state.fieldErrors['lat'],
            state.fieldErrors['lng'],
            state.fieldErrors['address'],
            state.fieldErrors['address_details'],
          ].whereType<String>().join('\n');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LocationSelectButtonWidget(
                        label: l10n.savedAddressLocation,
                        icon: widget.type.icon,
                        accentColor: AppColors.primary,
                        value: state.location,
                        placeholder: l10n.savedAddressPickOnMap,
                        onTap: state.isSaving
                            ? null
                            : () => _pickLocation(context, state.location),
                      ),
                      if (locationError.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingS),
                        Text(
                          locationError,
                          style: const TextStyle(color: AppColors.errorText, fontSize: 13),
                        ),
                      ],
                      if (_needsLabel) ...[
                        const SizedBox(height: AppConstants.paddingXL),
                        AuthTextFieldWidget(
                          controller: _labelController,
                          label: l10n.savedAddressLabel,
                          hint: l10n.savedAddressLabelHint,
                          prefixIcon: Icons.label_outline_rounded,
                          maxLength: _maxLabelLength,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !state.isSaving,
                          serverError: state.fieldErrors['label'],
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? l10n.savedAddressLabelRequired
                              : null,
                        ),
                      ],
                      const SizedBox(height: AppConstants.paddingXL),
                      if (state.errorMessage != null) ...[
                        AuthErrorBannerWidget(message: state.errorMessage!),
                        const SizedBox(height: AppConstants.paddingM),
                      ],
                      AuthPrimaryButtonWidget(
                        label: l10n.save,
                        isLoading: state.isSaving,
                        onPressed: state.location == null ? null : () => _submit(cubit),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit(SavedAddressFormCubit cubit) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    cubit.save(label: _labelController.text);
  }

  Future<void> _pickLocation(
    BuildContext context,
    PickedLocationModel? current,
  ) async {
    final cubit = context.read<SavedAddressFormCubit>();
    final picked = await Navigator.of(context).pushNamed(
      AppRouter.locationPicker,
      arguments: LocationPickerRouteArgs(
        title: context.l10n.savedAddressPickOnMap,
        isPickup: true,
        initialLocation: current,
      ),
    );
    if (picked is PickedLocationModel) cubit.setLocation(picked);
  }
}
