import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_state.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';
import 'saved_address_chips_widget.dart';

/// Under the From / To card while a point is being placed: the customer's
/// saved places as one-tap chips, and the confirm button.
class MapPickActionsWidget extends StatefulWidget {
  /// The details already typed for the point being edited, if any.
  final String? initialDetails;

  /// Called with the details text when the customer confirms the pin.
  final ValueChanged<String> onConfirm;

  const MapPickActionsWidget({
    super.key,
    required this.initialDetails,
    required this.onConfirm,
  });

  @override
  State<MapPickActionsWidget> createState() => _MapPickActionsWidgetState();
}

class _MapPickActionsWidgetState extends State<MapPickActionsWidget> {
  /// Details of a place picked from the saved ones replace the earlier ones,
  /// since they describe that place. No field asks for them here.
  late String _details = widget.initialDetails ?? '';

  void _selectSaved(SavedAddressModel address) {
    _details = address.addressDetails ?? '';
    FocusScope.of(context).unfocus();
    context.read<MapPickCubit>().selectSaved(address.toPickedLocation());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocSelector<
          SavedAddressesCubit,
          SavedAddressesState,
          List<SavedAddressModel>
        >(
          selector: (state) => state.addresses,
          builder: (context, addresses) => SavedAddressChipsWidget(
            addresses: addresses,
            onSelected: _selectSaved,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        BlocSelector<
          MapPickCubit,
          MapPickState,
          ({bool typing, bool searching, bool canConfirm})
        >(
          selector: (state) => (
            typing: state.isTyping,
            searching: state.isSearching,
            canConfirm: state.canConfirm,
          ),
          // Typed text is searched first; once the pin is on a place the
          // button confirms it.
          builder: (context, view) => view.typing
              ? AuthPrimaryButtonWidget(
                  label: context.l10n.search,
                  isLoading: view.searching,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    context.read<MapPickCubit>().searchTyped();
                  },
                )
              : AuthPrimaryButtonWidget(
                  label: context.l10n.confirmLocation,
                  isLoading: false,
                  onPressed: view.canConfirm
                      ? () => widget.onConfirm(_details)
                      : null,
                ),
        ),
      ],
    );
  }
}
