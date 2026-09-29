import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Vertical pickup → (stops) → dropoff timeline.
class RideRouteWidget extends StatelessWidget {
  final String? pickup;
  final String? dropoff;
  final List<String?> stops;

  const RideRouteWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.stops = const [],
  });

  @override
  Widget build(BuildContext context) {
    final fallback = context.l10n.mapLocationFallback;
    final points = <_Point>[
      _Point(pickup ?? fallback, AppColors.success),
      for (final s in stops) _Point(s ?? fallback, AppColors.accent),
      _Point(dropoff ?? fallback, AppColors.error),
    ];
    return Column(
      children: [
        for (var i = 0; i < points.length; i++)
          _RoutePointRow(point: points[i], isLast: i == points.length - 1),
      ],
    );
  }
}

class _Point {
  final String text;
  final Color color;

  const _Point(this.text, this.color);
}

class _RoutePointRow extends StatelessWidget {
  final _Point point;
  final bool isLast;

  const _RoutePointRow({required this.point, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: point.color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Text(
                point.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
