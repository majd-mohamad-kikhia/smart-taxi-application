import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/app_surface_card_widget.dart';
import '../../data/models/report_trip_model.dart';
import 'report_route_widget.dart';
import 'report_trip_details_sheet_widget.dart';
import 'wallet_amount_widget.dart';

/// One completed trip in the month's list: when it ended and what the
/// customer paid, the two addresses, and its distance and time. Tapping it
/// opens all of the trip's details.
class ReportTripRowWidget extends StatelessWidget {
  final ReportTripModel trip;

  const ReportTripRowWidget({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final minutes = trip.durationMin;
    final facts = [
      if (trip.distanceKm > 0)
        l10n.distanceKm(trip.distanceKm.toStringAsFixed(1)),
      if (minutes != null && minutes > 0) l10n.durationMinutesShort('$minutes'),
    ].join(' · ');

    return AppSurfaceCardWidget(
      onTap: () => showReportTripDetailsSheet(context, trip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  formatDateTime(context, trip.completedAt),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Flexible(
                child: WalletAmountWidget(
                  amount: trip.price,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          ReportRouteWidget(
            pickup: trip.pickupAddress,
            dropoff: trip.dropoffAddress,
          ),
          if (facts.isNotEmpty || trip.rating != null) ...[
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                if (facts.isNotEmpty)
                  Expanded(
                    child: Text(
                      facts,
                      style: textTheme.bodyLarge?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (trip.rating != null) _RatingBadge(rating: trip.rating!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final int rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 20, color: AppColors.star),
        const SizedBox(width: 4),
        Text(
          '$rating',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
