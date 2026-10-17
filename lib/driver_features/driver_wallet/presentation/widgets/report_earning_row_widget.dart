import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../data/models/report_earning_model.dart';
import 'report_earning_details_sheet_widget.dart';
import 'report_route_widget.dart';
import 'wallet_amount_widget.dart';

/// One trip's money in the month's earnings list: when it ended, what the
/// driver kept (the big green figure), and under it the price the customer
/// paid and the commission taken. Tapping it opens the full split.
class ReportEarningRowWidget extends StatelessWidget {
  final ReportEarningModel earning;

  const ReportEarningRowWidget({super.key, required this.earning});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyLarge?.copyWith(
      color: context.colors.textSecondary,
    );

    return AppSurfaceCardWidget(
      onTap: () => showReportEarningDetailsSheet(context, earning),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  formatDateTime(context, earning.completedAt),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Flexible(
                child: WalletAmountWidget(
                  amount: earning.driverEarning,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                  ),
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          ReportRouteWidget(
            pickup: earning.pickupAddress,
            dropoff: earning.dropoffAddress,
            maxLines: 1,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(child: Text(l10n.reportTripPrice, style: secondary)),
              Text(formatNewSyp(l10n, earning.price), style: secondary),
            ],
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reportCommissionRate(_rate(earning.commissionRate)),
                  style: secondary,
                ),
              ),
              Text(
                formatNewSyp(l10n, -earning.commissionAmount),
                style: secondary?.copyWith(color: context.colors.errorText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "5" for 5.0, "7.5" for 7.5.
  static String _rate(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();
}
