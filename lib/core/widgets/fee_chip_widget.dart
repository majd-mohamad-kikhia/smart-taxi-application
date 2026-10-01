import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Small dark pill that floats over the live map, e.g. "Waiting fee:
/// 1500 SYP" or "Track trip". It is a dark surface with a hairline border
/// and light text, so it reads on the dark map, and the yellow icon sits on
/// it at full contrast.
class FeeChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeeChipWidget({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: AppConstants.paddingXS),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
