import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_error_banner_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'saved_address_chips_widget.dart';

/// Bottom of the home map while a point is being placed: the address under
/// the pin, the saved places and the confirm button.
class MapPickPanelWidget extends StatefulWidget {
  /// The details already typed for the point being edited, if any.
  final String? initialDetails;

  /// Called with the details text when the customer confirms the pin.
  final ValueChanged<String> onConfirm;

  /// A message about the GPS button (permission off, no address found).
  final String? errorMessage;

  const MapPickPanelWidget({
    super.key,
    required this.initialDetails,
    required this.onConfirm,
    required this.errorMessage,
  });

  @override
  State<MapPickPanelWidget> createState() => _MapPickPanelWidgetState();
}

class _MapPickPanelWidgetState extends State<MapPickPanelWidget> {
  /// Details of a place picked from the saved ones replace the earlier ones,
  /// since they describe that place. No field asks for them here.
  late String _details = widget.initialDetails ?? '';

  void _selectSaved(SavedAddressModel address) {
    _details = address.addressDetails ?? '';
    context.read<MapPickCubit>().selectSaved(address.toPickedLocation());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.errorMessage != null) ...[
          AuthErrorBannerWidget(message: widget.errorMessage!),
          const SizedBox(height: AppConstants.paddingM),
        ],
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: AppColors.neutralSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AddressRowWidget(),
              _SavedPlaces(onSelected: _selectSaved),
              const SizedBox(height: AppConstants.paddingM),
              BlocSelector<MapPickCubit, MapPickState, bool>(
                selector: (state) => state.canConfirm,
                builder: (context, canConfirm) => AuthPrimaryButtonWidget(
                  label: l10n.confirmLocation,
                  isLoading: false,
                  onPressed: canConfirm
                      ? () => widget.onConfirm(_details)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The customer's saved places as one-tap chips under the address; hidden
/// when there are none. Rebuilds only when the list changes.
class _SavedPlaces extends StatelessWidget {
  final ValueChanged<SavedAddressModel> onSelected;

  const _SavedPlaces({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SavedAddressesCubit, SavedAddressesState, List<SavedAddressModel>>(
      selector: (state) => state.addresses,
      builder: (context, addresses) => SavedAddressChipsWidget(
        addresses: addresses,
        onSelected: onSelected,
      ),
    );
  }
}

/// The address under the pin — or that it is being looked up, or that none
/// was found with a retry.
class _AddressRowWidget extends StatelessWidget {
  const _AddressRowWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<MapPickCubit, MapPickState>(
      buildWhen: (previous, current) =>
          previous.address != current.address ||
          previous.isResolving != current.isResolving,
      builder: (context, state) {
        final address = state.address;
        return Row(
          children: [
            const Icon(
              Icons.pin_drop_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: Text(
                address ??
                    (state.isResolving
                        ? l10n.locationResolving
                        : l10n.locationUnresolved),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: address != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (address == null && !state.isResolving)
              TextButton(
                onPressed: context.read<MapPickCubit>().retryResolve,
                child: Text(l10n.retry),
              ),
          ],
        );
      },
    );
  }
}
