import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/ride_fare_breakdown_model.dart';
import '../theme/app_colors.dart';
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
    String price(double amount) => l10n.priceSyp(amount.toStringAsFixed(0));
    final waiting = fare.waiting;

    return Column(
      children: [
        if (fare.baseFare > 0)
          _BillRow(label: l10n.fareBaseFare, value: price(fare.baseFare)),
        _BillRow(label: l10n.fareDistanceFare, value: price(fare.distanceFare)),
        if (fare.stopsFeeTotal > 0)
          _BillRow(label: l10n.fareStopsFee, value: price(fare.stopsFeeTotal)),
        if (fare.waitingFee > 0)
          _BillRow(
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
          _BillRow(
            label: l10n.farePauses,
            detail: l10n.farePausesDetail(
              '${fare.pauseCount}',
              LiveFeeCardWidget.clock(fare.pauseTotalSeconds),
            ),
            value: price(fare.pauseFeeTotal),
          ),
        if (showTotal)
          _BillRow(
            label: l10n.fareTotal,
            value: price(fare.finalPrice),
            isBold: true,
          ),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String? detail;
  final String value;
  final bool isBold;

  const _BillRow({
    required this.label,
    required this.value,
    this.detail,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.w800 : FontWeight.w600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (detail != null)
                    TextSpan(
                      text: '  ($detail)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: weight,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: weight,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
