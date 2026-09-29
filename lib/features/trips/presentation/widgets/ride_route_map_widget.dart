import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Read-only preview of the path a finished ride actually drove: the blue
/// driven line with a start (green) and end (red) pin, fitted to the map.
/// Styled like the app's other maps (dark style, no native controls) and
/// non-interactive so it never fights the details screen's scrolling.
class RideRouteMapWidget extends StatefulWidget {
  final List<RoutePointModel> route;

  const RideRouteMapWidget({super.key, required this.route});

  @override
  State<RideRouteMapWidget> createState() => _RideRouteMapWidgetState();
}

class _RideRouteMapWidgetState extends State<RideRouteMapWidget> {
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_styles/dark_map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  LatLngBounds _bounds(List<LatLng> points) {
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    return LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = [for (final p in widget.route) LatLng(p.lat, p.lng)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: GoogleMap(
          style: _mapStyle,
          initialCameraPosition: CameraPosition(target: points.first, zoom: 14),
          onMapCreated: (controller) => controller.moveCamera(
            CameraUpdate.newLatLngBounds(_bounds(points), 40),
          ),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          polylines: {
            Polyline(
              polylineId: const PolylineId('driven_route'),
              points: points,
              color: AppColors.mapRouteDriven,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: points.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          },
        ),
      ),
    );
  }
}
