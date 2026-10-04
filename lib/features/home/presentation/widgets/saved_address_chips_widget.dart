import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/presentation/saved_address_type_ui.dart';
import '../../../../core/theme/app_colors.dart';

/// The customer's saved places as one-tap chips under a From / To card;
/// tapping one fills that point. Scrolls sideways when there are many.
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
    if (addresses.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: AppConstants.paddingS),
        itemCount: addresses.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.paddingS),
        itemBuilder: (context, index) {
          final address = addresses[index];
          return ActionChip(
            avatar: Icon(address.type.icon, size: 18, color: AppColors.primary),
            label: Text(address.title(l10n)),
            tooltip: address.address,
            onPressed: () => onSelected(address),
            backgroundColor: AppColors.neutralSurface,
            side: const BorderSide(color: AppColors.border),
            labelStyle: Theme.of(context).textTheme.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
          );
        },
      ),
    );
  }
}
