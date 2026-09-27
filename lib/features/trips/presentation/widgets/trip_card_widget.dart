import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_history_model.dart';

/// Single trip history card with route, metrics, and action buttons.
class TripCardWidget extends StatelessWidget {
  final TripHistoryModel trip;
  final VoidCallback? onReorder;
  final VoidCallback? onInvoice;
  final VoidCallback? onDetails;
  final VoidCallback? onRate;
  final VoidCallback? onHelp;

  const TripCardWidget({
    super.key,
    required this.trip,
    this.onReorder,
    this.onInvoice,
    this.onDetails,
    this.onRate,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = trip.isDimmed ? 0.65 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: category + time + status
            Row(
              children: [
                Icon(
                  trip.status == TripHistoryStatus.cancelled
                      ? Icons.cancel_outlined
                      : Icons.airline_seat_recline_extra_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.categoryName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _formatTime(trip.dateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: trip.status, label: trip.statusLabel),
              ],
            ),
            if (trip.vehicleDetails != '—') ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  trip.vehicleDetails,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Route row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini map placeholder
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _RoutePoint(
                        color: AppColors.primary,
                        isSquare: false,
                        address: trip.pickupAddress,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            width: 2,
                            height: 12,
                            color: AppColors.border,
                          ),
                        ),
                      ),
                      _RoutePoint(
                        color: AppColors.accent,
                        isSquare: true,
                        address: trip.destinationAddress,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    trip.priceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (trip.metricsLabel.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.metricsLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (trip.paymentMethod != null)
                    Text(
                      trip.paymentMethod!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
            if (trip.cancelReason != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.cancelReason!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onHelp,
                    child: const Row(
                      children: [
                        Icon(Icons.help_outline, size: 14, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text(
                          'مساعدة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            _ActionButtons(
              trip: trip,
              onReorder: onReorder,
              onInvoice: onInvoice,
              onDetails: onDetails,
              onRate: onRate,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  final TripHistoryStatus status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == TripHistoryStatus.cancelled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.backgroundMuted : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCancelled ? Icons.close_rounded : Icons.check_circle_rounded,
            size: 12,
            color: isCancelled ? AppColors.textSecondary : AppColors.primary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isCancelled ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final Color color;
  final bool isSquare;
  final String address;

  const _RoutePoint({
    required this.color,
    required this.isSquare,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSquare ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 12,
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

class _ActionButtons extends StatelessWidget {
  final TripHistoryModel trip;
  final VoidCallback? onReorder;
  final VoidCallback? onInvoice;
  final VoidCallback? onDetails;
  final VoidCallback? onRate;

  const _ActionButtons({
    required this.trip,
    this.onReorder,
    this.onInvoice,
    this.onDetails,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (trip.status == TripHistoryStatus.cancelled) {
      return const SizedBox.shrink();
    }

    // First completed trip: invoice + reorder
    // Second: details + rate
    final showReorder = trip.distanceKm != null;

    return Row(
      children: [
        Expanded(
          child: _SecondaryBtn(
            label: showReorder ? 'عرض الفاتورة' : 'تفاصيل الرحلة',
            icon: showReorder
                ? Icons.receipt_outlined
                : Icons.info_outline_rounded,
            onTap: showReorder ? onInvoice : onDetails,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PrimaryBtn(
            label: showReorder ? 'إعادة الطلب' : 'تقييم الكابتن',
            icon: showReorder
                ? Icons.refresh_rounded
                : Icons.star_outline_rounded,
            onTap: showReorder ? onReorder : onRate,
          ),
        ),
      ],
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryBtn({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
