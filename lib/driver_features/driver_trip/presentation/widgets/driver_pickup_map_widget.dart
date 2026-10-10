import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Map for the driver who just accepted the ride: the pickup pin, the
/// driver's own position and the Google road between them ([route]) once it
/// is known; the camera frames both. Before that, just the pickup. Styled
/// the same way as the pickup/dropoff location pickers (dark map style,
/// no native controls).
class DriverPickupMapWidget extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double? driverLat;
  final double? driverLng;
  final List<RoutePointModel> route;

  const DriverPickupMapWidget({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    this.driverLat,
    this.driverLng,
    this.route = const [],
  });

  @override
  State<DriverPickupMapWidget> createState() => _DriverPickupMapWidgetState();
}

class _DriverPickupMapWidgetState extends State<DriverPickupMapWidget> {
  String? _mapStyle;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  @override
  void didUpdateWidget(DriverPickupMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLat != widget.pickupLat ||
        oldWidget.pickupLng != widget.pickupLng) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.pickupLat, widget.pickupLng)),
      );
    }
    final routeAppeared =
        widget.route.length >= 2 && oldWidget.route.length < 2;
    if (routeAppeared) _frameDriverAndPickup();
  }

  /// Shows the driver and the pickup together (never tighter than ~440 m).
  void _frameDriverAndPickup() {
    final controller = _controller;
    final lat = widget.driverLat, lng = widget.driverLng;
    if (controller == null || lat == null || lng == null) return;
    const minSpan = 0.004;
    var south = math.min(lat, widget.pickupLat),
        north = math.max(lat, widget.pickupLat);
    var west = math.min(lng, widget.pickupLng),
        east = math.max(lng, widget.pickupLng);
    if (north - south < minSpan) {
      final pad = (minSpan - (north - south)) / 2;
      south -= pad;
      north += pad;
    }
    if (east - west < minSpan) {
      final pad = (minSpan - (east - west)) / 2;
      west -= pad;
      east += pad;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        96,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString(
      'assets/map_styles/dark_map_style.json',
    );
    if (mounted) setState(() => _mapStyle = style);
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.pickupLat, widget.pickupLng);
    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: point, zoom: 15),
      onMapCreated: (controller) => _controller = controller,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      polylines: {
        if (widget.route.length >= 2)
          Polyline(
            polylineId: const PolylineId('driver_to_pickup'),
            points: [for (final p in widget.route) LatLng(p.lat, p.lng)],
            color: AppColors.mapRoutePlanned,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
      },
      markers: {
        if (widget.driverLat != null && widget.driverLng != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(widget.driverLat!, widget.driverLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        Marker(
          markerId: const MarkerId('pickup'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      },
    );
  }
}
