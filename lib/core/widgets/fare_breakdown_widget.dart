import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_fare_breakdown_model.dart';
import '../utils/format_price.dart';
import 'bill_row_widget.dart';
import 'live_fee_card_widget.dart';

/// Bill lines for a finished ride — base fare, distance, stops, waiting
/// (e.g. "3 min × 500") and the total. Zero-value optional lines are
/// hidden; the total is the server's `final_price`. Shared by the driver's
/// and the customer's end-of-trip dialogs.
class FareBreakdownWidget extends StatelessWidget {
  final RideFareBreakdownModel fare;
  final bool showTotal;

  const FareBreakdownWidget({
    super.key,
    required this.fare,
    this.showTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String price(double amount) => l10n.priceSyp(formatPrice(amount));
    final waiting = fare.waiting;

    return Column(
      children: [
        if (fare.baseFare > 0)
          BillRowWidget(label: l10n.fareBaseFare, value: price(fare.baseFare)),
        BillRowWidget(label: l10n.fareDistanceFare, value: price(fare.distanceFare)),
        if (fare.stopsFeeTotal > 0)
          BillRowWidget(label: l10n.fareStopsFee, value: price(fare.stopsFeeTotal)),
        if (fare.waitingFee > 0)
          BillRowWidget(
            label: l10n.fareWaiting,
            detail: waiting == null
                ? null
                : l10n.fareWaitingDetail(
                    '${waiting.billableMinutes}',
                    price(waiting.pricePerMinute),
                  ),
            value: price(fare.waitingFee),
          ),
        if (fare.pauseFeeTotal > 0)
          BillRowWidget(
            label: l10n.farePauses,
            detail: l10n.farePausesDetail(
              '${fare.pauseCount}',
              LiveFeeCardWidget.clock(fare.pauseTotalSeconds),
            ),
            value: price(fare.pauseFeeTotal),
          ),
        if (showTotal)
          BillRowWidget(
            label: l10n.fareTotal,
            value: price(fare.finalPrice),
            isBold: true,
          ),
      ],
    );
  }
}
