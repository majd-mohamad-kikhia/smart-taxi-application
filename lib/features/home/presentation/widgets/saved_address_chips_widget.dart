import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/data/models/saved_place_preset.dart';
import '../../../../core/saved_addresses/presentation/saved_address_type_ui.dart';
import '../../../../core/saved_addresses/presentation/saved_place_slots.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/place_accent.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';

/// The customer's saved places as one-tap chips under a From / To card;
/// tapping one fills that point. The customer's own named places come first,
/// then the fixed ones (home, work, gym…) — always shown, and a tap on one
/// that isn't saved yet says so. Scrolls sideways when there are many.
class SavedAddressChipsWidget extends StatelessWidget {
  final List<SavedAddressModel> addresses;
  final ValueChanged<SavedAddressModel> onSelected;

  const SavedAddressChipsWidget({
    super.key,
    required this.addresses,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slots = SavedPlaceSlots.from(addresses);
    final chips = <_Chip>[
      for (final address in slots.custom)
        _Chip(
          title: address.title(l10n),
          icon: address.icon,
          accent: address.accent,
          address: address,
        ),
      _Chip(
        title: SavedAddressType.home.name(l10n),
        icon: SavedAddressType.home.icon,
        accent: SavedAddressType.home.accent,
        address: slots.home,
      ),
      _Chip(
        title: SavedAddressType.work.name(l10n),
        icon: SavedAddressType.work.icon,
        accent: SavedAddressType.work.accent,
        address: slots.work,
      ),
      for (final preset in SavedPlacePreset.values)
        _Chip(
          title: preset.name(l10n),
          icon: preset.icon,
          accent: preset.accent,
          address: slots.presets[preset],
        ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: AppConstants.paddingS),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.paddingS),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final address = chip.address;
          final isSaved = address != null;
          final foreground = chip.accent.foreground(context);
          return ActionChip(
            avatar: Icon(
              chip.icon,
              size: 18,
              color: isSaved ? foreground : foreground.withValues(alpha: 0.55),
            ),
            label: Text(chip.title),
            tooltip: address?.address,
            onPressed: isSaved
                ? () => onSelected(address)
                : () => showAppSnackBar(
                      context,
                      l10n.savedPlaceNotSaved(chip.title),
                      type: AppSnackBarType.error,
                    ),
            backgroundColor:
                isSaved ? chip.accent.wash(context) : context.colors.neutralSurface,
            side: BorderSide(
              color: isSaved
                  ? foreground.withValues(alpha: 0.45)
                  : context.colors.border,
            ),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSaved
                      ? context.colors.textPrimary
                      : context.colors.textTertiary,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
          );
        },
      ),
    );
  }
}

class _Chip {
  final String title;
  final IconData icon;
  final PlaceAccent accent;
  final SavedAddressModel? address;

  const _Chip({
    required this.title,
    required this.icon,
    required this.accent,
    required this.address,
  });
}
