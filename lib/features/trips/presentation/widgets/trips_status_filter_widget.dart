import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_history_model.dart';

/// Horizontal chip row filtering rides by status; `null` = all.
class TripsStatusFilterWidget extends StatelessWidget {
  final RideStatus? selected;
  final ValueChanged<RideStatus?> onSelected;

  const TripsStatusFilterWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [
          _Chip(
            label: context.l10n.all,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in RideStatus.values)
            _Chip(
              label: status.label(context.l10n),
              isSelected: selected == status,
              onTap: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.backgroundWhite,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
