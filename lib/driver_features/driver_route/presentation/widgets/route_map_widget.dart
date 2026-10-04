import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/car_heading_tracker.dart';
import '../../../../core/utils/taxi_marker_icon.dart';

/// Full-bleed map for the driver's private route: the path driven so far,
/// the driver's own taxi, and — once the route is finished — start and end
/// pins with the camera fitted to the whole route.
class RouteMapWidget extends StatefulWidget {
  final double? carLat;
  final double? carLng;
  final List<RoutePointModel> path;

  /// The route is over: show start/end pins and fit the camera to it.
  final bool isFinished;

  /// Changes every time the driver taps the locate button; the map then
  /// centres on the taxi.
  final int locateRequest;

  const RouteMapWidget({
    super.key,
    required this.carLat,
    required this.carLng,
    required this.path,
    required this.isFinished,
    required this.locateRequest,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  // Shown until the first GPS fix — the app-wide default map centre.
  static const _fallbackCenter = LatLng(
    AppConstants.defaultMapLat,
    AppConstants.defaultMapLng,
  );

  GoogleMapController? _controller;
  String? _mapStyle;
  BitmapDescriptor? _taxiIcon;
  final _heading = CarHeadingTracker();

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

  Future<void> _loadTaxiIcon() async {
    final icon = await TaxiMarkerIcon.load();
    if (mounted) setState(() => _taxiIcon = icon);
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString(
      'assets/map_styles/dark_map_style.json',
    );
    if (mounted) setState(() => _mapStyle = style);
  }

  @override
  void didUpdateWidget(covariant RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.carLat != oldWidget.carLat || widget.carLng != oldWidget.carLng) {
      final car = _car;
      if (car != null) _heading.update(car);
    }
    if (widget.locateRequest != oldWidget.locateRequest) {
      _centerOnCar();
      return;
    }
    final finishedNow = widget.isFinished && !oldWidget.isFinished;
    if (finishedNow ||
        (widget.carLat != oldWidget.carLat ||
            widget.carLng != oldWidget.carLng)) {
      _moveCamera();
    }
  }

  void _moveCamera() {
    final controller = _controller;
    if (controller == null) return;
    if (widget.isFinished && widget.path.length >= 2) {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsOfPath(), 80),
      );
      return;
    }
    final car = _car;
    if (car != null && !widget.isFinished) {
      controller.animateCamera(CameraUpdate.newLatLng(car));
    }
  }

  /// The locate button: centre on the taxi, in any step.
  void _centerOnCar() {
    final car = _car;
    if (car == null) return;
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(car, 16));
  }

  LatLngBounds _boundsOfPath() {
    var minLat = widget.path.first.lat, maxLat = minLat;
    var minLng = widget.path.first.lng, maxLng = minLng;
    for (final p in widget.path) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    final taxiIcon = _taxiIcon;
    final path = [for (final p in widget.path) LatLng(p.lat, p.lng)];

    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(
        target: car ?? (path.isNotEmpty ? path.last : _fallbackCenter),
        zoom: 15,
      ),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
        _moveCamera();
      },
      polylines: {
        if (path.length >= 2)
          Polyline(
            polylineId: const PolylineId('route'),
            points: path,
            color: AppColors.mapRouteDriven,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
      },
      markers: {
        if (widget.isFinished && path.isNotEmpty) ...{
          Marker(
            markerId: const MarkerId('start'),
            position: path.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: path.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        },
        // The driver's own taxi, in every step (also once finished).
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
