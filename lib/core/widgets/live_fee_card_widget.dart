import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The card shared by the live fee timers (waiting at pickup, trip pause):
/// a title, a mm:ss clock, a coloured status line, an optional rules line
/// and the fee so far. Presentational only — see `RideWaitingTimerWidget`
/// and `RidePauseTimerWidget` for where the numbers come from.
class LiveFeeCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final int elapsedSeconds;
  final String? statusText;
  final String? rulesText;
  final String? feeText;
  final Color accent;

  const LiveFeeCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.elapsedSeconds,
    required this.accent,
    this.statusText,
    this.rulesText,
    this.feeText,
  });

  /// mm:ss for a number of seconds.
  static String clock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.08),
          AppColors.backgroundWhite,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  clock(elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (statusText != null)
                  Text(
                    statusText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                if (rulesText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    rulesText!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (feeText != null)
            Text(
              feeText!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }
}
