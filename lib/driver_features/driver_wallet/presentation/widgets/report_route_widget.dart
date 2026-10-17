import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';

/// A trip's pickup and drop-off addresses, one under the other, each with
/// its own marker. A missing address reads as "—".
class ReportRouteWidget extends StatelessWidget {
  final String? pickup;
  final String? dropoff;

  /// Lines of text each address may take before it is cut with "…".
  final int maxLines;

  const ReportRouteWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressLine(
          icon: Icons.trip_origin_rounded,
          color: context.colors.primaryContent,
          address: pickup,
          maxLines: maxLines,
        ),
        const SizedBox(height: AppConstants.paddingS),
        _AddressLine(
          icon: Icons.location_on_rounded,
          color: context.colors.accentContent,
          address: dropoff,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? address;
  final int maxLines;

  const _AddressLine({
    required this.icon,
    required this.color,
    required this.address,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Text(
            address ?? '—',
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
