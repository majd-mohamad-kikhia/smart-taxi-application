import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/route_session_model.dart';
import 'route_duration_format.dart';

/// The small card in the top corner once the route is finished: distance,
/// waiting at the start, trip time, the stops and the driving time.
class RouteSummaryCardWidget extends StatelessWidget {
  final RouteSessionModel session;

  const RouteSummaryCardWidget({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = session.finishedAt ?? DateTime.now();
    final stops = session.pauseCount == 0
        ? formatRouteDuration(Duration.zero)
        : '${formatRouteDuration(session.pausedDuration(now))} (×${session.pauseCount})';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.85,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.routeSummaryTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: l10n.fareDistanceDriven,
                        value: l10n.distanceKm(
                          (session.distanceMeters / 1000).toStringAsFixed(2),
                        ),
                        isHighlighted: true,
                      ),
                      _SummaryRow(
                        label: l10n.routeSummaryWaiting,
                        value: formatRouteDuration(
                          session.waitingDuration(now),
                        ),
                      ),
                      _SummaryRow(
                        label: l10n.routeSummaryTripTime,
                        value: formatRouteDuration(session.tripDuration(now)),
                      ),
                      _SummaryRow(label: l10n.routeSummaryStops, value: stops),
                      _SummaryRow(
                        label: l10n.routeSummaryDriving,
                        value: formatRouteDuration(
                          session.drivingDuration(now),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = isHighlighted ? FontWeight.w800 : FontWeight.w600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: weight,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: weight,
              color: isHighlighted ? AppColors.success : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
