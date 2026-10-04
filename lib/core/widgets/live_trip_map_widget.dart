import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_point_model.dart';
import '../theme/app_colors.dart';
import '../utils/car_heading_tracker.dart';
import '../utils/taxi_marker_icon.dart';

/// Full-bleed map for a trip that is underway: the moving taxi, the
/// destination pin, and two lines: the planned road route ([routePoints],
/// yellow, fixed from start to end) and the path the car has actually
/// driven ([drivenPath], blue). Shared by the driver's and the customer's
/// in-progress screens so both see the same picture.
///
/// The camera fits the car and destination on the first fix, then follows
/// the car. The planned line appears once its route has loaded.
class LiveTripMapWidget extends StatefulWidget {
  final double? carLat;
  final double? carLng;
  final double destinationLat;
  final double destinationLng;
  final List<RoutePointModel> routePoints;
  final List<RoutePointModel> drivenPath;

  const LiveTripMapWidget({
    super.key,
    this.carLat,
    this.carLng,
    required this.destinationLat,
    required this.destinationLng,
    this.routePoints = const [],
    this.drivenPath = const [],
  });

  @override
  State<LiveTripMapWidget> createState() => _LiveTripMapWidgetState();
}

class _LiveTripMapWidgetState extends State<LiveTripMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  BitmapDescriptor? _taxiIcon;
  final _heading = CarHeadingTracker();
  bool _hasFitted = false;

  LatLng get _destination => LatLng(widget.destinationLat, widget.destinationLng);

  LatLng? get _car {
    final lat = widget.carLat;
    final lng = widget.carLng;
    return lat != null && lng != null ? LatLng(lat, lng) : null;
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadTaxiIcon();
    final car = _car;
    if (car != null) _heading.update(car);
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_styles/dark_map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  Future<void> _loadTaxiIcon() async {
    final icon = await TaxiMarkerIcon.load();
    if (mounted) setState(() => _taxiIcon = icon);
  }

  @override
  void didUpdateWidget(covariant LiveTripMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carLat != widget.carLat || oldWidget.carLng != widget.carLng) {
      final car = _car;
      if (car != null) _heading.update(car);
      _moveCamera();
    }
  }

  void _moveCamera() {
    final controller = _mapController;
    final car = _car;
    if (controller == null || car == null) return;

    if (!_hasFitted) {
      _hasFitted = true;
      controller.animateCamera(CameraUpdate.newLatLngBounds(_boundsOf(car, _destination), 80));
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(car));
    }
  }

  LatLngBounds _boundsOf(LatLng a, LatLng b) {
    return LatLngBounds(
      southwest: LatLng(math.min(a.latitude, b.latitude), math.min(a.longitude, b.longitude)),
      northeast: LatLng(math.max(a.latitude, b.latitude), math.max(a.longitude, b.longitude)),
    );
  }

  Polyline _line(String id, List<RoutePointModel> points, Color color, int zIndex) {
    return Polyline(
      polylineId: PolylineId(id),
      points: [for (final p in points) LatLng(p.lat, p.lng)],
      color: color,
      width: 5,
      zIndex: zIndex,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    final taxiIcon = _taxiIcon;
    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: car ?? _destination, zoom: 15),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _moveCamera();
      },
      polylines: {
        if (widget.routePoints.length >= 2)
          _line('planned_route', widget.routePoints, AppColors.mapRoutePlanned, 1),
        if (widget.drivenPath.length >= 2)
          _line('driven_path', widget.drivenPath, AppColors.mapRouteDriven, 2),
      },
      markers: {
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        if (car != null && taxiIcon != null)
          Marker(
            markerId: const MarkerId('car'),
            position: car,
            icon: taxiIcon,
            rotation: _heading.bearing,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
          ),
      },
    );
  }
}
