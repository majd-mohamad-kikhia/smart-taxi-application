import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// A pill the user picks one of ("Waiting too long", "Plans changed", ...).
/// The selected state is shown by a check mark and the green wash and
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
      checkmarkColor: context.colors.primaryContent,
      backgroundColor: context.colors.backgroundMuted,
      selectedColor: context.colors.primarySurface,
      side: BorderSide(color: selected ? AppColors.primary : context.colors.border),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? context.colors.primaryContent : context.colors.textPrimary,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
