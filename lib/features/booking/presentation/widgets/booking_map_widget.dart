import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/booking_route_model.dart';

/// Map showing pickup → destination route with ETA overlay and map FABs.
class BookingMapWidget extends StatelessWidget {
  final BookingRouteModel route;

  const BookingMapWidget({super.key, required this.route});

  List<LatLng> get _routePoints {
    // Approximate curved route between pickup and destination
    final p = route.pickupLatLng;
    final d = route.destinationLatLng;
    return [
      p,
      LatLng(
        p.latitude + (d.latitude - p.latitude) * 0.3,
        p.longitude + (d.longitude - p.longitude) * 0.15,
      ),
      LatLng(
        p.latitude + (d.latitude - p.latitude) * 0.6,
        p.longitude + (d.longitude - p.longitude) * 0.55,
      ),
      d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mid = LatLng(
      (route.pickupLatLng.latitude + route.destinationLatLng.latitude) / 2,
      (route.pickupLatLng.longitude + route.destinationLatLng.longitude) / 2,
    );

    return RepaintBoundary(
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mid,
              initialZoom: 12.8,
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
                    strokeWidth: 5,
                    borderColor: AppColors.primaryDark,
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: route.pickupLatLng,
                    width: 200,
                    height: 70,
                    alignment: Alignment.topCenter,
                    child: const _PickupMarker(),
                  ),
                  Marker(
                    point: route.destinationLatLng,
                    width: 28,
                    height: 28,
                    child: const _DestinationMarker(),
                  ),
                ],
              ),
            ],
          ),
          // Map FABs (left side in RTL visual = physical left)
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 60,
            child: const Column(
              children: [
                _MapFab(icon: Icons.my_location_rounded),
                SizedBox(height: 10),
                _MapFab(icon: Icons.traffic_rounded),
              ],
            ),
          ),
          // ETA floating card
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _EtaCard(
              durationLabel: route.durationLabel,
              distanceLabel: route.distanceLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupMarker extends StatelessWidget {
  const _PickupMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'اسحب الخريطة لتعديل نقطة الالتقاء بدقة',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.success,
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
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2.5),
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
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
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

class _EtaCard extends StatelessWidget {
  final String durationLabel;
  final String distanceLabel;

  const _EtaCard({required this.durationLabel, required this.distanceLabel});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  durationLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  distanceLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
