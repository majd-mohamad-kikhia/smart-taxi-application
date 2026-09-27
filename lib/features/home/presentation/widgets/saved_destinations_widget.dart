import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/saved_destination_model.dart';

/// Section showing the user's two primary saved destinations (Home & Work)
/// in a horizontally scrollable card layout.
class SavedDestinationsWidget extends StatelessWidget {
  final List<SavedDestinationModel> destinations;
  final void Function(String destinationId)? onDestinationTapped;
  final VoidCallback? onEditTapped;

  const SavedDestinationsWidget({
    super.key,
    required this.destinations,
    this.onDestinationTapped,
    this.onEditTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ─────────────────────────────
          Row(
            children: [
              const Text(
                'وجهاتك المحفوظة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEditTapped,
                child: const Text(
                  'تعديل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Destination Cards Row ──────────────────────
          Row(
            children: destinations.take(2).map((dest) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: destinations.indexOf(dest) == 0 ? 0 : 8,
                  ),
                  child: _DestinationCardWidget(
                    destination: dest,
                    onTap: () => onDestinationTapped?.call(dest.id),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Individual saved destination card with icon, name, address & ETA.
class _DestinationCardWidget extends StatelessWidget {
  final SavedDestinationModel destination;
  final VoidCallback? onTap;

  const _DestinationCardWidget({
    required this.destination,
    this.onTap,
  });

  IconData get _icon {
    return switch (destination.type) {
      DestinationType.home => Icons.home_rounded,
      DestinationType.work => Icons.business_rounded,
      DestinationType.favorite => Icons.favorite_rounded,
      DestinationType.custom => Icons.place_rounded,
    };
  }

  Color get _iconColor {
    return switch (destination.type) {
      DestinationType.home => AppColors.primary,
      DestinationType.work => const Color(0xFF1E40AF),
      DestinationType.favorite => AppColors.accent,
      DestinationType.custom => AppColors.textSecondary,
    };
  }

  Color get _iconBackground {
    return switch (destination.type) {
      DestinationType.home => AppColors.primarySurface,
      DestinationType.work => const Color(0xFFEFF6FF),
      DestinationType.favorite => AppColors.accentSurface,
      DestinationType.custom => AppColors.backgroundMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                color: _iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            // ── Text ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${destination.address} • ${destination.estimatedMinutes} د',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
