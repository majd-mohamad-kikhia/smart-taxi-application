import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_pause_model.dart';
import '../theme/app_colors.dart';
import '../utils/format_price.dart';
import 'live_fee_card_widget.dart';
import 'second_ticker_widget.dart';

/// Live "trip paused" card, shared by the driver and customer apps: time
/// paused, included time left (or that it is over) and the fee of this
/// pause so far. Shows nothing when the trip isn't paused.
///
/// Included time reads green with a pause icon; once it is over the card
/// turns amber with a payments icon. Screen readers hear the card once when
/// it appears, then at each new billable minute. When the pause has no
/// price at all, the fee and the rules line are left out.
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
        String price(double amount) => l10n.priceSyp(formatPrice(amount));

        final isCharged = running.baseFee > 0 || running.pricePerMinute > 0;
        final isIncluded = snapshot.isIncluded;
        final feeText = isCharged ? price(snapshot.fee) : null;
        final rulesText = isCharged
            ? l10n.pauseRules(
                price(running.baseFee),
                '${running.includedMinutes}',
                price(running.pricePerMinute),
              )
            : null;
        final feeSpoken = feeText == null ? null : '${l10n.liveFeeSoFar}: $feeText';
        final announcement = [
          if (snapshot.extraMinutes <= 1) l10n.pauseIncludedOver,
          ?feeSpoken,
        ].join('. ');

        return LiveFeeCardWidget(
          icon: isIncluded
              ? Icons.pause_circle_outline_rounded
              : (isCharged ? Icons.payments_outlined : Icons.timer_off_outlined),
          title: l10n.pauseTripPaused,
          elapsedSeconds: snapshot.elapsedSeconds,
          statusText: isIncluded
              ? l10n.pauseIncludedLeft(
                  LiveFeeCardWidget.clock(snapshot.includedSecondsLeft),
                )
              : l10n.pauseIncludedOver,
          rulesText: rulesText,
          feeText: feeText,
          accent: isIncluded
              ? AppColors.success
              : (isCharged ? AppColors.warning : AppColors.textSecondary),
          semanticsLabel: [
            l10n.pauseTripPaused,
            LiveFeeCardWidget.spoken(l10n, snapshot.elapsedSeconds),
            isIncluded
                ? l10n.pauseIncludedLeft(
                    LiveFeeCardWidget.spoken(l10n, snapshot.includedSecondsLeft),
                  )
                : l10n.pauseIncludedOver,
            ?feeSpoken,
            ?rulesText,
          ].join('. '),
          announceOnShow: true,
          phaseKey: isIncluded ? 'included' : 'extra-${snapshot.extraMinutes}',
          phaseAnnouncement:
              isIncluded || announcement.isEmpty ? null : announcement,
        );
      },
    );
  }
}
