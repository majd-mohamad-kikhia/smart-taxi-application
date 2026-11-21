import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

/// Where an offered trip goes from and to: the pickup and the destination
/// one under the other, joined by a thin line. Each address is a single line
/// by default; with [showDetails] the address details ("2nd floor, blue
/// door") show under it, and the address may wrap to two lines.
class OrderRouteWidget extends StatelessWidget {
  final String pickup;
  final String? pickupDetails;
  final String dropoff;
  final String? dropoffDetails;
  final bool showDetails;

  const OrderRouteWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.pickupDetails,
    this.dropoffDetails,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        _StopRow(
          icon: Icons.trip_origin_rounded,
          iconColor: colors.primaryContent,
          label: pickup,
          details: showDetails ? pickupDetails : null,
          maxLines: showDetails ? 2 : 1,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 9),
          child: SizedBox(
            height: 10,
            child: VerticalDivider(
              width: 1,
              thickness: 1.5,
              color: colors.borderLight,
            ),
          ),
        ),
        _StopRow(
          icon: Icons.location_on_rounded,
          iconColor: colors.accentContent,
          label: dropoff,
          details: showDetails ? dropoffDetails : null,
          maxLines: showDetails ? 2 : 1,
        ),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? details;
  final int maxLines;

  const _StopRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.maxLines,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (details != null)
                Text(
                  details!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
