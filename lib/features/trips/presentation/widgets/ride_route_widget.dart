import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Vertical pickup → (stops) → drop-off timeline. Each point has its own
/// glyph and a spoken label ("From", "Stop 1", "To"), so the order never
/// depends on dot color. Pickup and drop-off use the same yellow and amber as
/// the order screen.
///
/// Addresses are capped at [maxLines] on a card; leave it null on the
/// details screen, where the full address is the point.
class RideRouteWidget extends StatelessWidget {
  final String? pickup;
  final String? dropoff;

  /// Building, floor, landmark — a quieter line under the address.
  final String? pickupDetails;
  final String? dropoffDetails;
  final List<String?> stops;
  final int? maxLines;

  const RideRouteWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.pickupDetails,
    this.dropoffDetails,
    this.stops = const [],
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fallback = l10n.mapLocationFallback;
    final points = <_Point>[
      _Point(
        text: pickup ?? fallback,
        details: pickupDetails,
        label: l10n.fromLabel,
        icon: Icons.trip_origin_rounded,
        color: AppColors.primary,
      ),
      for (var i = 0; i < stops.length; i++)
        _Point(
          text: stops[i] ?? fallback,
          label: l10n.detailStopLabel(i + 1),
          icon: Icons.circle,
          color: AppColors.textSecondary,
          iconSize: 10,
        ),
      _Point(
        text: dropoff ?? fallback,
        details: dropoffDetails,
        label: l10n.toLabel,
        icon: Icons.location_on_rounded,
        color: AppColors.accent,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < points.length; i++)
          _RoutePointRow(
            point: points[i],
            isLast: i == points.length - 1,
            maxLines: maxLines,
          ),
      ],
    );
  }
}

class _Point {
  final String text;
  final String? details;
  final String label;
  final IconData icon;
  final Color color;
  final double iconSize;

  const _Point({
    required this.text,
    this.details,
    required this.label,
    required this.icon,
    required this.color,
    this.iconSize = 18,
  });
}

class _RoutePointRow extends StatelessWidget {
  final _Point point;
  final bool isLast;
  final int? maxLines;

  const _RoutePointRow({
    required this.point,
    required this.isLast,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final details = point.details?.trim();
    final hasDetails = details != null && details.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: hasDetails
          ? '${point.label}: ${point.text}. $details'
          : '${point.label}: ${point.text}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 18,
              child: Column(
                children: [
                  SizedBox(
                    height: 18,
                    child: Icon(point.icon, size: point.iconSize, color: point.color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 1.5, color: AppColors.border),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppConstants.paddingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.text,
                      maxLines: maxLines,
                      overflow: maxLines == null ? null : TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                    if (hasDetails)
                      Text(
                        details,
                        maxLines: maxLines,
                        overflow: maxLines == null ? null : TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
