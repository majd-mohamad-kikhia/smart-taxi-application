import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'route_duration_format.dart';

/// One live stopwatch on the route map: a coloured icon badge, a small
/// label, the big clock and a blinking "live" dot. Compact and centred,
/// so it floats over the map instead of stretching across it.
///
/// Pure display — the caller passes the elapsed [duration] and rebuilds it
/// every second.
class RouteTimerCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Duration duration;
  final Color accent;

  const RouteTimerCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.duration,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // The dot blinks with the seconds, in step with the clock.
    final isDotLit = duration.inSeconds.isEven;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutralSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 20, 10),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: isDotLit ? 1 : 0.25,
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Digits always read left to right, also in Arabic.
                  Text(
                    formatRouteDuration(duration),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
