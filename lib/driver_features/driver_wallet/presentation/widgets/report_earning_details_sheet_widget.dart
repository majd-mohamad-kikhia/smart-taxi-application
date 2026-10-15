import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../../../core/widgets/bill_row_widget.dart';
import '../../data/models/report_earning_model.dart';
import 'report_details_sheet_widget.dart';
import 'report_route_widget.dart';

/// "Trip price − commission = you earn" for one trip, with what the price is
/// made of under it (only the parts that are more than zero). A price typed
/// by the office is marked as such.
Future<void> showReportEarningDetailsSheet(
  BuildContext context,
  ReportEarningModel earning,
) {
  final l10n = context.l10n;
  final fees = earning.fees;
  final rate = earning.commissionRate == earning.commissionRate.roundToDouble()
      ? earning.commissionRate.toStringAsFixed(0)
      : earning.commissionRate.toString();
  final lines = <(String, double)>[
    (l10n.reportFeeDistance, fees.distanceFare),
    (l10n.reportFeeStops, fees.stopsFee),
    (l10n.reportFeeLocation, fees.locationFee),
    (l10n.reportFeePassengers, fees.passengersFee),
    (l10n.reportFeeNight, fees.nightFee),
    (l10n.reportFeeTime, fees.timeFee),
    (l10n.reportFeeWaiting, fees.waitingFee),
    (l10n.reportFeePause, fees.pauseFee),
  ].where((line) => line.$2 > 0).toList();

  return showReportDetailsSheet(
    context,
    title: formatDamascusDateTime(context, earning.completedAt),
    children: [
      ReportRouteWidget(
        pickup: earning.pickupAddress,
        dropoff: earning.dropoffAddress,
        maxLines: 4,
      ),
      const SizedBox(height: AppConstants.paddingL),
      BillRowWidget(
        label: l10n.reportTripPrice,
        value: formatSyp(l10n, earning.price),
      ),
      BillRowWidget(
        label: l10n.reportCommissionRate(rate),
        value: formatSignedPrice(l10n, -earning.commissionAmount),
        valueColor: context.colors.errorText,
      ),
      const SizedBox(height: AppConstants.paddingS),
      // What the driver keeps stands apart from the lines that lead to it.
      AppSurfaceCardWidget(
        color: context.colors.successSurface,
        bordered: false,
        radius: AppConstants.radiusMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        child: BillRowWidget(
          label: l10n.fareYourEarning,
          value: formatSyp(l10n, earning.driverEarning),
          isBold: true,
          valueColor: AppColors.success,
        ),
      ),
      if (earning.priceIsFixed) ...[
        const SizedBox(height: AppConstants.paddingM),
        Text(
          l10n.reportFixedPrice,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
        ),
      ],
      if (lines.isNotEmpty) ...[
        const SizedBox(height: AppConstants.paddingXL),
        Text(
          l10n.reportFeesTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppConstants.paddingS),
        for (final line in lines)
          BillRowWidget(label: line.$1, value: formatSyp(l10n, line.$2)),
      ],
    ],
  );
}
