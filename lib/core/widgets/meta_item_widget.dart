import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// A small icon and label for a fact about a trip, such as its distance or
/// duration. Put several in a `Wrap` so they flow onto a second line at a
/// large text size instead of squeezing their neighbours.
class MetaItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetaItemWidget({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppConstants.paddingXS),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
