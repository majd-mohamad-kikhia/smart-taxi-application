import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_waiting_model.dart';
import '../theme/app_colors.dart';
import 'live_fee_card_widget.dart';
import 'second_ticker_widget.dart';

/// Live "waiting at pickup" card, shared by the driver and customer apps:
/// time waited, free time left (or that it is over) and the fee so far.
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
        String price(double amount) => l10n.priceSyp(amount.toStringAsFixed(0));
        final isCharged = waiting.pricePerMinute > 0;

        return LiveFeeCardWidget(
          icon: Icons.timer_outlined,
          title: l10n.waitingAtPickup,
          elapsedSeconds: snapshot.elapsedSeconds,
          statusText: snapshot.isFree
              ? l10n.waitingFreeLeft(
                  LiveFeeCardWidget.clock(snapshot.freeSecondsLeft),
                )
              : l10n.waitingFreeOver,
          rulesText: isCharged
              ? l10n.waitingRules(
                  '${waiting.freeMinutes}',
                  price(waiting.pricePerMinute),
                )
              : null,
          feeText: isCharged ? price(snapshot.fee) : null,
          accent: snapshot.isFree ? AppColors.success : AppColors.error,
        );
      },
    );
  }
}
