import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/driver_settings_cubit.dart';

/// Draggable control for the driver's ride-search radius. Whole
/// kilometers only, 1–10 km — the API itself allows fractional values up
/// to 100 km, but the product only exposes this coarser range in the UI.
///
/// A screen reader hears the value in kilometers ("5 km"), not as a
/// percentage, and [isUnsaved] says in words that the change is not saved
/// yet.
class SearchRadiusSliderWidget extends StatelessWidget {
  static const int minKm = DriverSettingsCubit.minKm;
  static const int maxKm = DriverSettingsCubit.maxKm;

  final int valueKm;
  final bool isUnsaved;
  final ValueChanged<int> onChanged;

  const SearchRadiusSliderWidget({
    super.key,
    required this.valueKm,
    required this.onChanged,
    this.isUnsaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.social_distance_rounded,
                color: context.colors.primaryContent,
                size: 20,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  l10n.searchRadiusTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primarySurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  l10n.distanceKm('$valueKm'),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.primaryContent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(l10n.searchRadiusDescription, style: textTheme.bodySmall),
          if (isUnsaved) ...[
            const SizedBox(height: AppConstants.paddingS),
            Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: context.colors.accentContent,
                ),
                const SizedBox(width: AppConstants.paddingXS),
                Text(
                  l10n.searchRadiusUnsaved,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primaryContent,
              inactiveTrackColor: context.colors.borderStrong,
              thumbColor: context.colors.primaryContent,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              valueIndicatorColor: context.colors.primaryContent,
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
              semanticFormatterCallback: (value) =>
                  l10n.distanceKm('${value.round()}'),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.distanceKm('$minKm'), style: textTheme.bodySmall),
                Text(l10n.distanceKm('$maxKm'), style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
