import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_history_model.dart';

/// Header with title, statement button, and past/scheduled tab switcher.
class TripsHeaderWidget extends StatelessWidget {
  final TripsTab selectedTab;
  final int pastCount;
  final int scheduledCount;
  final ValueChanged<TripsTab>? onTabChanged;

  const TripsHeaderWidget({
    super.key,
    required this.selectedTab,
    required this.pastCount,
    required this.scheduledCount,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'طلباتي ورحلاتي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.backgroundMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'كشف الحساب',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabPill(
                    label: 'الرحلات السابقة ($pastCount)',
                    icon: Icons.history_rounded,
                    selected: selectedTab == TripsTab.past,
                    onTap: () => onTabChanged?.call(TripsTab.past),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'المجدولة',
                    icon: Icons.calendar_today_rounded,
                    selected: selectedTab == TripsTab.scheduled,
                    showDot: scheduledCount > 0,
                    onTap: () => onTabChanged?.call(TripsTab.scheduled),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final VoidCallback? onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.selected,
    this.showDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 4),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
