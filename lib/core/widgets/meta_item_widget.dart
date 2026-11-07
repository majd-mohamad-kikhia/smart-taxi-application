import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// A small icon and label for a fact about a trip, such as its distance or
/// duration. Put several in a `Wrap` so they flow onto a second line at a
/// large text size instead of squeezing their neighbours.
///
/// [prominent] makes it bigger and bolder, for a fact the reader must see at
/// a glance (the distance on a driver's order card).
class MetaItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool prominent;

  const MetaItemWidget({
    super.key,
    required this.icon,
    required this.label,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: prominent ? 22 : 16,
          color: prominent ? context.colors.textSecondary : context.colors.textTertiary,
        ),
        const SizedBox(width: AppConstants.paddingXS),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: prominent ? context.colors.textPrimary : context.colors.textSecondary,
              fontSize: prominent ? 16 : null,
              fontWeight: prominent ? FontWeight.w700 : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
