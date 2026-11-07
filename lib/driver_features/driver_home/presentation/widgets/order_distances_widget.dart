import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';

/// The two distances of an order card, one under the other: from the driver
/// to the customer, and from the pickup to the destination.
class OrderDistancesWidget extends StatelessWidget {
  final double toPickupKm;
  final double tripKm;

  const OrderDistancesWidget({
    super.key,
    required this.toPickupKm,
    required this.tripKm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _DistanceLine(
          icon: Icons.social_distance_rounded,
          label: l10n.distanceFromYouToCustomer,
          value: l10n.distanceKm(toPickupKm.toStringAsFixed(1)),
        ),
        const SizedBox(height: 8),
        _DistanceLine(
          icon: Icons.route_outlined,
          label: l10n.distanceFromPickupToDropoff,
          value: l10n.distanceKm(tripKm.toStringAsFixed(1)),
        ),
      ],
    );
  }
}

class _DistanceLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DistanceLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 22, color: colors.primaryContent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
