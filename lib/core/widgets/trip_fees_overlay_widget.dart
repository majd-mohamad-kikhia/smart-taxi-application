import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_pause_model.dart';
import '../utils/format_price.dart';
import 'fee_chip_widget.dart';
import 'ride_pause_timer_widget.dart';

/// What sits at the top of the live map while a trip is in progress, for
/// both the driver and the customer: the final waiting fee, the pause fees
/// of closed pauses, and — while paused — the live pause timer. Renders
/// nothing when there is nothing to show.
class TripFeesOverlayWidget extends StatelessWidget {
  final double waitingFee;
  final RidePauseModel? pause;

  const TripFeesOverlayWidget({
    super.key,
    required this.waitingFee,
    required this.pause,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String price(double amount) => formatSyp(l10n, amount);
    final pause = this.pause;
    final isPaused = pause?.isPaused ?? false;
    final pauseTotal = pause?.totalFee ?? 0;

    if (waitingFee <= 0 && pauseTotal <= 0 && !isPaused) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPaused) ...[
              RidePauseTimerWidget(pause: pause!),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (waitingFee > 0)
                  FeeChipWidget(
                    icon: Icons.timer_outlined,
                    label: l10n.waitingFeeFinal(price(waitingFee)),
                  ),
                if (pauseTotal > 0)
                  FeeChipWidget(
                    icon: Icons.pause_circle_outline_rounded,
                    label: l10n.pauseFeeTotal(price(pauseTotal)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
