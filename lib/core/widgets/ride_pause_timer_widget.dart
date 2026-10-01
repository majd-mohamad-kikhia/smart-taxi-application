import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_pause_model.dart';
import '../theme/app_colors.dart';
import 'live_fee_card_widget.dart';
import 'second_ticker_widget.dart';

/// Live "trip paused" card, shared by the driver and customer apps: time
/// paused, included time left (or that it is over) and the fee of this
/// pause so far. Shows nothing when the trip isn't paused.
///
/// Display only — the numbers come from [RidePauseModel.snapshotAt],
/// counting up from the server's `elapsed_seconds`.
class RidePauseTimerWidget extends StatelessWidget {
  final RidePauseModel pause;

  const RidePauseTimerWidget({super.key, required this.pause});

  @override
  Widget build(BuildContext context) {
    final running = pause.current;
    if (!pause.isPaused || running == null) return const SizedBox.shrink();

    return SecondTickerWidget(
      active: true,
      builder: (context) {
        final l10n = context.l10n;
        final snapshot = pause.snapshotAt(DateTime.now());
        if (snapshot == null) return const SizedBox.shrink();
        String price(double amount) => l10n.priceSyp(amount.toStringAsFixed(0));

        return LiveFeeCardWidget(
          icon: Icons.pause_circle_outline_rounded,
          title: l10n.pauseTripPaused,
          elapsedSeconds: snapshot.elapsedSeconds,
          statusText: snapshot.isIncluded
              ? l10n.pauseIncludedLeft(
                  LiveFeeCardWidget.clock(snapshot.includedSecondsLeft),
                )
              : l10n.pauseIncludedOver,
          rulesText: l10n.pauseRules(
            price(running.baseFee),
            '${running.includedMinutes}',
            price(running.pricePerMinute),
          ),
          feeText: price(snapshot.fee),
          accent: snapshot.isIncluded ? AppColors.primary : AppColors.error,
        );
      },
    );
  }
}
