import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../models/trip_eta_model.dart';
import '../utils/format_distance.dart';
import 'fee_chip_widget.dart';

/// Floating pill with the time and road distance left, e.g. "Driver arrives
/// in 5 min · 2.3 km". [towardsPickup] says what is being counted: the
/// driver's way to the pickup, or the trip's way to the destination.
class TripEtaChipWidget extends StatelessWidget {
  final TripEtaModel eta;
  final bool towardsPickup;

  const TripEtaChipWidget({
    super.key,
    required this.eta,
    required this.towardsPickup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = l10n.durationMinutesShort('${eta.minutes}');
    final distance = formatDistance(l10n, eta.distanceMeters);

    return FeeChipWidget(
      icon: towardsPickup ? Icons.local_taxi_rounded : Icons.flag_rounded,
      label: towardsPickup
          ? l10n.tripEtaToPickup(duration, distance)
          : l10n.tripEtaToDestination(duration, distance),
    );
  }
}
