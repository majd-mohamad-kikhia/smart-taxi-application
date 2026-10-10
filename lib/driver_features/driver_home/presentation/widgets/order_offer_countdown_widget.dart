import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/second_ticker_widget.dart';

/// The driver's turn on an order: the seconds left and a bar draining to
/// zero at [expiresAt] (UTC). Offers go out in waves of a few drivers, each
/// with [totalSeconds] to accept before the server withdraws the card.
///
/// It only shows the time; the server decides when the turn is over (and
/// removes the card), so nothing here blocks the accept button.
class OrderOfferCountdownWidget extends StatelessWidget {
  final DateTime expiresAt;
  final int totalSeconds;

  /// From here on the bar and number turn red.
  static const _urgentSeconds = 3;

  const OrderOfferCountdownWidget({
    super.key,
    required this.expiresAt,
    required this.totalSeconds,
  });

  Duration get _left {
    final left = expiresAt.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final start = (_left.inMilliseconds / (totalSeconds * 1000)).clamp(
      0.0,
      1.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecondTickerWidget(
          active: _left > Duration.zero,
          builder: (context) {
            final seconds = (_left.inMilliseconds / 1000).ceil();
            final urgent = seconds <= _urgentSeconds;
            return Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: urgent ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.orderOfferSecondsLeft(seconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.error : AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        // Drains smoothly over the time that is left, whatever rebuilds the
        // card around it: the tween's end never changes, so it isn't restarted.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: start, end: 0),
          duration: _left,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: AppColors.borderLight,
              color: value * totalSeconds <= _urgentSeconds
                  ? AppColors.error
                  : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
