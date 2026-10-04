import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/order_offer_model.dart';
import '../theme/app_colors.dart';
import 'meta_item_widget.dart';
import 'passengers_fee_meta_widget.dart';
import 'ride_note_widget.dart';

/// Where an order goes, for the driver: pickup, any [stops], drop-off —
/// with the customer's address details under each point — how many people
/// get in (once known) and any extra price for them, and the customer's note.
/// Once the ride is underway ([showPickup] false) only the drop-off and the
/// note are left.
class OrderRouteDetailsWidget extends StatelessWidget {
  final OrderOfferModel order;
  final bool showPickup;
  final List<String> stops;

  const OrderRouteDetailsWidget({
    super.key,
    required this.order,
    this.showPickup = true,
    this.stops = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPickup) ...[
          _PointRow(
            icon: Icons.radio_button_checked_rounded,
            color: AppColors.success,
            label: l10n.fromLabel,
            address: order.pickupAddress,
            details: order.pickupAddressDetails,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < stops.length; i++) ...[
            _PointRow(
              icon: Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              label: l10n.detailStopLabel(i + 1),
              address: stops[i],
            ),
            const SizedBox(height: 10),
          ],
        ],
        _PointRow(
          icon: Icons.location_on_rounded,
          color: AppColors.error,
          label: l10n.toLabel,
          address: order.dropoffAddress,
          details: order.dropoffAddressDetails,
        ),
        if (order.passengersCount != null || order.passengersFee > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (order.passengersCount != null)
                MetaItemWidget(
                  icon: Icons.groups_rounded,
                  label: l10n.passengersCount(order.passengersCount!),
                ),
              if (order.passengersFee > 0) PassengersFeeMetaWidget(fee: order.passengersFee),
            ],
          ),
        ],
        if (order.note != null) ...[
          const SizedBox(height: 12),
          RideNoteWidget(note: order.note!),
        ],
      ],
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final String? details;

  const _PointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final shown = address.isEmpty ? context.l10n.mapLocationFallback : address;
    return Semantics(
      label: details == null ? '$label: $shown' : '$label: $shown. $details',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shown,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (details != null)
                  Text(
                    details!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
