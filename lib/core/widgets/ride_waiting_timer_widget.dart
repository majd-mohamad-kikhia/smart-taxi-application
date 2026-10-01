import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_waiting_model.dart';
import '../theme/app_colors.dart';
import '../utils/format_price.dart';
import 'live_fee_card_widget.dart';
import 'second_ticker_widget.dart';

/// Live "waiting at pickup" card, shared by the driver and customer apps:
/// time waited, free time left (or that it is over) and the fee so far.
///
/// Free time reads green with a timer icon; once it is over (and a price
/// applies) the card turns amber with a payments icon, and screen readers
/// are told once, then again for each new billable minute.
///
/// Display only — every number comes from [RideWaitingModel.snapshotAt],
/// which counts up from the server's `elapsed_seconds`. Only the card is
/// repainted every second, not the screen around it.
class RideWaitingTimerWidget extends StatelessWidget {
  final RideWaitingModel waiting;

  const RideWaitingTimerWidget({super.key, required this.waiting});

  @override
  Widget build(BuildContext context) {
    return SecondTickerWidget(
      active: waiting.isRunning,
      builder: (context) {
        final l10n = context.l10n;
        final snapshot = waiting.snapshotAt(DateTime.now());
        String price(double amount) => l10n.priceSyp(formatPrice(amount));

        final isCharged = waiting.pricePerMinute > 0;
        final isFree = snapshot.isFree;
        final feeText = isCharged ? price(snapshot.fee) : null;
        final rulesText = isCharged
            ? l10n.waitingRules(
                '${waiting.freeMinutes}',
                price(waiting.pricePerMinute),
              )
            : null;
        final feeSpoken = feeText == null ? null : '${l10n.liveFeeSoFar}: $feeText';
        final announcement = [
          if (snapshot.billableMinutes <= 1) l10n.waitingFreeOver,
          ?feeSpoken,
        ].join('. ');

        return LiveFeeCardWidget(
          icon: isFree
              ? Icons.timer_outlined
              : (isCharged ? Icons.payments_outlined : Icons.timer_off_outlined),
          title: l10n.waitingAtPickup,
          elapsedSeconds: snapshot.elapsedSeconds,
          statusText: isFree
              ? l10n.waitingFreeLeft(
                  LiveFeeCardWidget.clock(snapshot.freeSecondsLeft),
                )
              : l10n.waitingFreeOver,
          rulesText: rulesText,
          feeText: feeText,
          accent: isFree
              ? AppColors.success
              : (isCharged ? AppColors.warning : AppColors.textSecondary),
          semanticsLabel: [
            l10n.waitingAtPickup,
            LiveFeeCardWidget.spoken(l10n, snapshot.elapsedSeconds),
            isFree
                ? l10n.waitingFreeLeft(
                    LiveFeeCardWidget.spoken(l10n, snapshot.freeSecondsLeft),
                  )
                : l10n.waitingFreeOver,
            ?feeSpoken,
            ?rulesText,
          ].join('. '),
          phaseKey: isFree ? 'free' : 'over-${snapshot.billableMinutes}',
          phaseAnnouncement: isFree || announcement.isEmpty ? null : announcement,
        );
      },
    );
  }
}
