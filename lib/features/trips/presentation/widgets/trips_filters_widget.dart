import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_history_model.dart';

/// Search field + horizontal filter chips for trip history.
class TripsFiltersWidget extends StatelessWidget {
  final TripFilter selectedFilter;
  final Map<TripFilter, int> filterCounts;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<TripFilter>? onFilterChanged;

  const TripsFiltersWidget({
    super.key,
    required this.selectedFilter,
    required this.filterCounts,
    this.onSearchChanged,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'ابحث بالوجهة أو التاريخ أو الكابتن...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'الكل (${filterCounts[TripFilter.all] ?? 0})',
                selected: selectedFilter == TripFilter.all,
                onTap: () => onFilterChanged?.call(TripFilter.all),
              ),
              _FilterChip(
                label: 'مكتملة (${filterCounts[TripFilter.completed] ?? 0})',
                selected: selectedFilter == TripFilter.completed,
                onTap: () => onFilterChanged?.call(TripFilter.completed),
              ),
              _FilterChip(
                label: 'ملغاة (${filterCounts[TripFilter.cancelled] ?? 0})',
                selected: selectedFilter == TripFilter.cancelled,
                onTap: () => onFilterChanged?.call(TripFilter.cancelled),
              ),
              _FilterChip(
                label: 'عمل (${filterCounts[TripFilter.business] ?? 0})',
                selected: selectedFilter == TripFilter.business,
                icon: Icons.work_outline_rounded,
                onTap: () => onFilterChanged?.call(TripFilter.business),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFE8EEF8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
