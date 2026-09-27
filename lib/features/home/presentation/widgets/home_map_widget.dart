import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive OpenStreetMap widget showing the user's location
/// and nearby available drivers.
/// Wrapped in a [RepaintBoundary] for optimal paint performance.
class HomeMapWidget extends StatelessWidget {
  const HomeMapWidget({super.key});

  // Riyadh – Al Olaya district coordinates
  static final _center = LatLng(24.6877, 46.6858);

  static final _nearbyDrivers = [
    LatLng(24.6900, 46.6820),
    LatLng(24.6855, 46.6900),
    LatLng(24.6840, 46.6840),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: AppConstants.mapHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.zero),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.8,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              // ── OSM Tile Layer ─────────────────────────────
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.userAgentPackage,
              ),
              // ── Markers ────────────────────────────────────
              MarkerLayer(
                markers: [
                  // User location marker
                  Marker(
                    point: _center,
                    width: 130,
                    height: 76,
                    child: const _UserLocationMarker(),
                  ),
                  // Nearby driver markers
                  ..._nearbyDrivers.map(
                    (point) => Marker(
                      point: point,
                      width: 36,
                      height: 36,
                      child: const _DriverMarker(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White bubble + pin icon for user's current location.
class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'موقعك الحال',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.primary,
          size: 30,
        ),
      ],
    );
  }
}

/// Small teal car icon for nearby drivers.
class _DriverMarker extends StatelessWidget {
  const _DriverMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
