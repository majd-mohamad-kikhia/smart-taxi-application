import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/price_text_widget.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';
import '../../../../core/widgets/meta_item_widget.dart';
import '../../../../core/widgets/ride_note_widget.dart';

/// A single ride offer on the driver home screen. [isAccepting] shows a
/// spinner in place of the button's label; [enabled] disables the button
/// while another card's accept is in flight (only one accept at a time).
class DriverOrderCardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PricePill(price: order.estimatedPrice, isEstimate: order.priceIsEstimate),
              const Spacer(),
              Icon(Icons.social_distance_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                context.l10n.distanceKmToPickup(order.distanceToPickupKm.toStringAsFixed(1)),
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LocationRow(
            icon: Icons.radio_button_checked_rounded,
            iconColor: AppColors.success,
            label: order.pickupAddress,
            details: order.pickupAddressDetails,
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 9),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(width: 1, thickness: 1.5, color: AppColors.borderLight),
            ),
          ),
          _LocationRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: order.dropoffAddress,
            details: order.dropoffAddressDetails,
          ),
          if (order.note != null) ...[
            const SizedBox(height: 12),
            RideNoteWidget(note: order.note!, maxLines: 3),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              MetaItemWidget(
                icon: Icons.route_outlined,
                label: context.l10n.distanceKm(order.distanceKm.toStringAsFixed(1)),
              ),
              MetaItemWidget(
                icon: Icons.schedule_rounded,
                label: context.l10n.durationMinutesShort('${order.estimatedDurationMin}'),
              ),
              if (order.passengersCount != null)
                MetaItemWidget(
                  icon: Icons.groups_rounded,
                  label: context.l10n.passengersCount(order.passengersCount!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // The card being accepted stays full yellow with a visible spinner;
          // the other cards' buttons dim to a muted yellow while it is in
          // flight (only one accept at a time).
          AuthPrimaryButtonWidget(
            label: context.l10n.driverAcceptTrip,
            isLoading: isAccepting,
            onPressed: enabled ? onAccept : null,
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
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: PriceTextWidget(
        price: price,
        prefix: isEstimate ? '~' : '',
        alignment: CrossAxisAlignment.start,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? details;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (details != null)
                Text(
                  details!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
