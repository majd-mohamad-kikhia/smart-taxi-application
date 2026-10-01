import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// A pill the user picks one of ("Waiting too long", "Plans changed", ...).
/// The selected state is shown by a check mark and the yellow wash and
/// border together, never by color alone, and the tap area stays 48dp tall.
class AppChoiceChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const AppChoiceChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.backgroundMuted,
      selectedColor: AppColors.primarySurface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
