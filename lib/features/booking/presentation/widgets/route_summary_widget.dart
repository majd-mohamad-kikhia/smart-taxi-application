import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/booking_route_model.dart';

/// Pickup / destination summary card with edit and swap actions.
class RouteSummaryWidget extends StatelessWidget {
  final BookingRouteModel route;
  final VoidCallback? onSwap;
  final VoidCallback? onEditPickup;

  const RouteSummaryWidget({
    super.key,
    required this.route,
    this.onSwap,
    this.onEditPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Edit / Swap column
          Column(
            children: [
              GestureDetector(
                onTap: onEditPickup,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onSwap,
                child: const Icon(
                  Icons.swap_vert_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Timeline + addresses
          Expanded(
            child: Column(
              children: [
                _AddressRow(
                  color: AppColors.success,
                  isSquare: false,
                  address: route.pickupAddress,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 7),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: 2,
                      height: 14,
                      color: AppColors.border,
                    ),
                  ),
                ),
                _AddressRow(
                  color: AppColors.accent,
                  isSquare: true,
                  address: route.destinationAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Color color;
  final bool isSquare;
  final String address;

  const _AddressRow({
    required this.color,
    required this.isSquare,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSquare ? BorderRadius.circular(3) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
