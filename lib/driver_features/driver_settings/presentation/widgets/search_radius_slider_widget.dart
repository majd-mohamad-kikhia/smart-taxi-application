import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Draggable control for the driver's ride-search radius. Whole
/// kilometers only, 1–10 km — the API itself allows fractional values up
/// to 100 km, but the product only exposes this coarser range in the UI.
class SearchRadiusSliderWidget extends StatelessWidget {
  static const int minKm = 1;
  static const int maxKm = 10;

  final int valueKm;
  final ValueChanged<int> onChanged;

  const SearchRadiusSliderWidget({
    super.key,
    required this.valueKm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.social_distance_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.searchRadiusTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  l10n.distanceKm('$valueKm'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.searchRadiusDescription,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.backgroundMuted,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Slider(
              value: valueKm.toDouble(),
              min: minKm.toDouble(),
              max: maxKm.toDouble(),
              divisions: maxKm - minKm,
              label: l10n.distanceKm('$valueKm'),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.distanceKm('$minKm'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
                Text(
                  l10n.distanceKm('$maxKm'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
