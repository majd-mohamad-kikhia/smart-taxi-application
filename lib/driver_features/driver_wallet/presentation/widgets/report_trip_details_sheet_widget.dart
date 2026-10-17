import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/widgets/bill_row_widget.dart';
import '../../data/models/report_trip_model.dart';
import 'report_details_sheet_widget.dart';
import 'report_route_widget.dart';

String _sourceLabel(AppLocalizations l10n, ReportOrderSource source) =>
    switch (source) {
      ReportOrderSource.app => l10n.reportSourceApp,
      ReportOrderSource.call => l10n.reportSourceCall,
      ReportOrderSource.whatsapp => l10n.reportSourceWhatsapp,
    };

/// Everything the server knows about one completed trip: the addresses, the
/// times (in Damascus time), distance and duration, the car, the customer,
/// how it was ordered, whether it is paid, and the customer's rating. Lines
/// the server left empty are not shown. The money split of the trip is in
/// the "trip earnings" list.
Future<void> showReportTripDetailsSheet(
  BuildContext context,
  ReportTripModel trip,
) {
  final l10n = context.l10n;
  String time(String? raw) => formatDateTime(context, raw);
  final minutes = trip.durationMin;
  return showReportDetailsSheet(
    context,
    title: l10n.reportTripNumber('${trip.id}'),
    children: [
      ReportRouteWidget(
        pickup: trip.pickupAddress,
        dropoff: trip.dropoffAddress,
        maxLines: 4,
      ),
      const SizedBox(height: AppConstants.paddingL),
      BillRowWidget(
        label: l10n.reportTripPrice,
        value: formatSyp(l10n, trip.price),
        isBold: true,
      ),
      BillRowWidget(
        label: l10n.reportPayment,
        value: trip.isPaid ? l10n.detailPaymentPaid : l10n.detailPaymentUnpaid,
      ),
      if (trip.paidAt != null)
        BillRowWidget(label: l10n.reportPaidAt, value: time(trip.paidAt)),
      if (trip.requestedAt != null)
        BillRowWidget(
          label: l10n.reportRequestedAt,
          value: time(trip.requestedAt),
        ),
      if (trip.startedAt != null)
        BillRowWidget(label: l10n.reportStartedAt, value: time(trip.startedAt)),
      if (trip.completedAt != null)
        BillRowWidget(
          label: l10n.reportCompletedAt,
          value: time(trip.completedAt),
        ),
      if (trip.distanceKm > 0)
        BillRowWidget(
          label: l10n.detailDistance,
          value: l10n.distanceKm(trip.distanceKm.toStringAsFixed(1)),
        ),
      if (minutes != null && minutes > 0)
        BillRowWidget(
          label: l10n.reportDuration,
          value: l10n.durationMinutesShort('$minutes'),
        ),
      if (trip.vehicleTypeName != null)
        BillRowWidget(
          label: l10n.reportVehicleType,
          value: trip.vehicleTypeName!,
        ),
      if (trip.customerFirstName != null)
        BillRowWidget(
          label: l10n.reportCustomer,
          value: trip.customerFirstName!,
        ),
      BillRowWidget(
        label: l10n.reportOrderSource,
        value: _sourceLabel(l10n, trip.orderSource),
      ),
      if (trip.rating != null)
        BillRowWidget(label: l10n.profileRating, value: '${trip.rating} / 5'),
    ],
  );
}
