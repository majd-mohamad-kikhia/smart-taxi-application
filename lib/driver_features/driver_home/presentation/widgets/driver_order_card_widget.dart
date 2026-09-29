import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/theme/app_colors.dart';

/// A single ride offer on the driver home screen. [isAccepting] shows a
/// spinner in place of the button; [enabled] disables it while another
/// card's accept is in flight (only one accept at a time).
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
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.route_outlined, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                context.l10n.distanceKm(order.distanceKm.toStringAsFixed(1)),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                context.l10n.durationMinutesShort('${order.estimatedDurationMin}'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? onAccept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.backgroundMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isAccepting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Text(
                      context.l10n.driverAcceptTrip,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
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
      child: Text(
        isEstimate
            ? '~${context.l10n.priceLyd(price.toStringAsFixed(2))}'
            : context.l10n.priceLyd(price.toStringAsFixed(2)),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _LocationRow({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
