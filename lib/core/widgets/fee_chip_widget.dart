import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// Small surface pill that floats over the live map, e.g. "Waiting fee:
/// 1500 SYP" or "Track trip". A solid surface with a hairline border and
/// one neutral shadow, so it reads on any map, with the green icon at full
/// contrast.
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
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: context.colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.colors.primaryContent, size: 16),
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
