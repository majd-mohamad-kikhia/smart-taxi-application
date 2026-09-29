import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';

/// One of the "From" / "To" location-pick cards on the create-request
/// screen. Styled as a distinct rounded card (icon chip + label + chosen
/// value + chevron) rather than a generic list row, so the pair reads as
/// a deliberate, unique pair of actions.
class LocationSelectButtonWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final PickedLocationModel? value;
  final String placeholder;

  /// `null` disables the card — e.g. while a ride order is already live
  /// and its pickup/dropoff can no longer be changed.
  final VoidCallback? onTap;

  const LocationSelectButtonWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(
                color: value != null
                    ? accentColor.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value?.displayLabel ?? placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
