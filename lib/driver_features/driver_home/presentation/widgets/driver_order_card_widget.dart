import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/meta_item_widget.dart';
import '../../../../core/widgets/passengers_fee_meta_widget.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/ride_note_widget.dart';
import 'order_route_widget.dart';
import 'vehicle_type_badge_widget.dart';

/// A single ride offer on the driver home screen, kept short so the map
/// stays visible above it: the car type and price, where the trip goes from
/// and to, the three numbers that decide it (distance to the customer, trip
/// distance, duration) and the accept button. Everything else — the note,
/// address details, passengers and their fee — sits under a "Details"
/// toggle.
///
/// [isAccepting] shows a spinner in place of the button's label; [enabled]
/// disables the button while another card's accept is in flight (only one
/// accept at a time).
class DriverOrderCardWidget extends StatefulWidget {
  final OrderOfferModel order;
  final bool isAccepting;
  final bool enabled;
  final VoidCallback onAccept;

  const DriverOrderCardWidget({
    super.key,
    required this.order,
    required this.isAccepting,
    required this.enabled,
    required this.onAccept,
  });

  @override
  State<DriverOrderCardWidget> createState() => _DriverOrderCardWidgetState();
}

class _DriverOrderCardWidgetState extends State<DriverOrderCardWidget> {
  bool _expanded = false;

  /// Whether there is anything to show under the "Details" toggle.
  bool get _hasDetails {
    final order = widget.order;
    return order.note != null ||
        order.pickupAddressDetails != null ||
        order.dropoffAddressDetails != null ||
        order.passengersCount != null ||
        order.passengersFee > 0;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: context.colors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            // The badge takes the room it needs (the price pill is small); it
            // only shrinks, and ellipsizes, when the row truly runs out.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.vehicleTypeName != null)
                Flexible(
                  child: VehicleTypeBadgeWidget(
                    name: order.vehicleTypeName!,
                    typeId: order.vehicleTypeId,
                  ),
                ),
              const SizedBox(width: AppConstants.paddingM),
              _PricePill(
                price: order.estimatedPrice,
                isEstimate: order.priceIsEstimate,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          OrderRouteWidget(
            pickup: order.pickupAddress,
            pickupDetails: order.pickupAddressDetails,
            dropoff: order.dropoffAddress,
            dropoffDetails: order.dropoffAddressDetails,
            showDetails: _expanded,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Wrap(
            spacing: AppConstants.paddingL,
            runSpacing: AppConstants.paddingXS,
            children: [
              MetaItemWidget(
                icon: Icons.social_distance_rounded,
                prominent: true,
                label: l10n.distanceKmToPickup(
                  order.distanceToPickupKm.toStringAsFixed(1),
                ),
              ),
              MetaItemWidget(
                icon: Icons.route_outlined,
                prominent: true,
                label: l10n.distanceKm(order.distanceKm.toStringAsFixed(1)),
              ),
              MetaItemWidget(
                icon: Icons.schedule_rounded,
                prominent: true,
                label: l10n.durationMinutesShort(
                  '${order.estimatedDurationMin}',
                ),
              ),
            ],
          ),
          if (_hasDetails) ...[
            _DetailsToggle(
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _ExtraDetails(order: order)
                  : const SizedBox(width: double.infinity),
            ),
          ] else
            const SizedBox(height: AppConstants.paddingM),
          // The card being accepted stays full green with a visible spinner;
          // the other cards' buttons dim to a muted green while it is in
          // flight (only one accept at a time).
          AuthPrimaryButtonWidget(
            label: l10n.driverAcceptTrip,
            isLoading: widget.isAccepting,
            onPressed: widget.enabled ? widget.onAccept : null,
          ),
        ],
      ),
    );
  }
}

/// The "Details" / "Hide details" row that opens and closes [_ExtraDetails].
class _DetailsToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _DetailsToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.colors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expanded ? l10n.orderOfferHideDetails : l10n.orderOfferShowDetails,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// What the card keeps back until the driver asks: the customer's note, the
/// number of passengers and the extra-passengers fee.
class _ExtraDetails extends StatelessWidget {
  final OrderOfferModel order;

  const _ExtraDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.note != null) ...[
            RideNoteWidget(note: order.note!, maxLines: 3),
            const SizedBox(height: AppConstants.paddingM),
          ],
          Wrap(
            spacing: AppConstants.paddingL,
            runSpacing: AppConstants.paddingXS,
            children: [
              if (order.passengersCount != null)
                MetaItemWidget(
                  icon: Icons.groups_rounded,
                  prominent: true,
                  label: l10n.passengersCount(order.passengersCount!),
                ),
              if (order.passengersFee > 0)
                PassengersFeeMetaWidget(fee: order.passengersFee),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final double price;
  final bool isEstimate;

  const _PricePill({required this.price, required this.isEstimate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: PriceTextWidget(
        price: price,
        prefix: isEstimate ? '~' : '',
        alignment: CrossAxisAlignment.start,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.primaryContent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
