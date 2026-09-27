import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/live_trip_model.dart';

/// Live map showing captain position, pickup, dashed route, ETA & safety FAB.
class TrackingMapWidget extends StatelessWidget {
  final LiveTripModel trip;

  const TrackingMapWidget({super.key, required this.trip});

  List<LatLng> get _routePoints {
    final c = trip.captainLatLng;
    final p = trip.pickupLatLng;
    return [
      c,
      LatLng(
        c.latitude + (p.latitude - c.latitude) * 0.45,
        c.longitude + (p.longitude - c.longitude) * 0.35,
      ),
      p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mid = LatLng(
      (trip.captainLatLng.latitude + trip.pickupLatLng.latitude) / 2,
      (trip.captainLatLng.longitude + trip.pickupLatLng.longitude) / 2,
    );

    return RepaintBoundary(
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mid,
              initialZoom: 14.2,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.userAgentPackage,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: AppColors.primary,
                    strokeWidth: 4,
                    pattern: StrokePattern.dashed(segments: [10, 8]),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: trip.captainLatLng,
                    width: 70,
                    height: 64,
                    child: _CaptainMarker(etaLabel: trip.etaShortLabel),
                  ),
                  Marker(
                    point: trip.pickupLatLng,
                    width: 22,
                    height: 22,
                    child: const _PickupDot(),
                  ),
                ],
              ),
            ],
          ),
          // Locate FAB
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 60,
            child: const _MapFab(icon: Icons.my_location_rounded),
          ),
          // ETA status card
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 60,
            right: 16,
            child: _EtaStatusCard(trip: trip),
          ),
          // Safety chip
          Positioned(
            left: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'أمان الرحلة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptainMarker extends StatelessWidget {
  final String etaLabel;

  const _CaptainMarker({required this.etaLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            etaLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickupDot extends StatelessWidget {
  const _PickupDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;

  const _MapFab({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }
}

class _EtaStatusCard extends StatelessWidget {
  final LiveTripModel trip;

  const _EtaStatusCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  trip.etaShortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.statusTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.statusSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
