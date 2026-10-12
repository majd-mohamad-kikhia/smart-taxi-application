import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/data/models/saved_place_preset.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_state.dart';
import '../../../../core/saved_addresses/presentation/saved_address_type_ui.dart';
import '../../../../core/saved_addresses/presentation/saved_place_slots.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_animated_dialog.dart';
import '../../../../core/widgets/app_loader_widget.dart';
import '../../../../core/widgets/app_neutral_button_widget.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';
import '../widgets/saved_address_tile_widget.dart';

/// "Saved places": Home, Work and the ready-made places (gym, school…) on
/// top (an "Add" row while missing), then the customer's own named places.
class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavedAddressesCubit>.value(
      value: sl<SavedAddressesCubit>()..load(),
      child: const _SavedAddressesView(),
    );
  }
}

class _SavedAddressesView extends StatelessWidget {
  const _SavedAddressesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.backgroundGray,
      appBar: AppBar(title: Text(l10n.savedAddressesTitle)),
      body: BlocBuilder<SavedAddressesCubit, SavedAddressesState>(
        builder: (context, state) {
          if (!state.isLoaded) {
            return state.isLoading || state.errorMessage == null
                ? const AppLoaderWidget()
                : _LoadError(
                    message: state.errorMessage!,
                    onRetry: context.read<SavedAddressesCubit>().load,
                  );
          }
          final slots = SavedPlaceSlots.from(state.addresses);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: RefreshIndicator(
                onRefresh: context.read<SavedAddressesCubit>().load,
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  children: [
                    _tile(context, state, SavedAddressType.home, slots.home),
                    const SizedBox(height: AppConstants.paddingM),
                    _tile(context, state, SavedAddressType.work, slots.work),
                    const SizedBox(height: AppConstants.paddingM),
                    for (final preset in SavedPlacePreset.values) ...[
                      _tile(
                        context,
                        state,
                        SavedAddressType.other,
                        slots.presets[preset],
                        preset: preset,
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                    ],
                    if (slots.custom.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        l10n.savedAddressOtherPlaces,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                    ],
                    for (final address in slots.custom) ...[
                      _tile(context, state, address.type, address),
                      const SizedBox(height: AppConstants.paddingM),
                    ],
                    AppNeutralButtonWidget(
                      label: l10n.savedAddressAddPlace,
                      icon: Icons.add_location_alt_outlined,
                      onPressed: () => _openForm(context, SavedAddressType.other),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    SavedAddressesState state,
    SavedAddressType type,
    SavedAddressModel? address, {
    SavedPlacePreset? preset,
  }) {
    return SavedAddressTileWidget(
      type: type,
      preset: preset,
      address: address,
      isDeleting: address != null && state.deletingId == address.id,
      onTap: () => _openForm(context, type, existing: address, preset: preset),
      onDelete: address == null ? null : () => _confirmDelete(context, address),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    SavedAddressType type, {
    SavedAddressModel? existing,
    SavedPlacePreset? preset,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final replaced = await Navigator.of(context).pushNamed(
      AppRouter.savedAddressForm,
      arguments: SavedAddressFormRouteArgs(
        type: type,
        existing: existing,
        preset: preset,
      ),
    );
    if (replaced is! bool) return;
    showAppSnackBarOn(
      messenger,
      replaced
          ? l10n.savedAddressReplaced(type.name(l10n))
          : l10n.savedAddressSaved,
      type: AppSnackBarType.success,
    );
  }

  void _confirmDelete(BuildContext context, SavedAddressModel address) {
    final l10n = context.l10n;
    final cubit = context.read<SavedAddressesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showAppDialog<void>(
      context: context,
      title: l10n.savedAddressDeleteTitle(address.title(l10n)),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.goBack,
      icon: Icons.delete_outline_rounded,
      tone: AppDialogTone.destructive,
      onConfirm: () async {
        final error = await cubit.delete(address.id);
        if (error != null) {
          showAppSnackBarOn(messenger, error, type: AppSnackBarType.error);
        }
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
