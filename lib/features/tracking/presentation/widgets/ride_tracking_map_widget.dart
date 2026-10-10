import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/car_heading_tracker.dart';
import '../../../../core/utils/taxi_marker_icon.dart';
import '../../data/models/ride_location_model.dart';

/// Live map: pickup/dropoff pins always shown, driver taxi + re-centering
/// once GPS starts arriving over `customer:driver_location`. Once the
/// driver's road to the pickup ([routePoints]) is known it is drawn, and the
/// camera keeps the driver and the pickup both in view instead of just
/// following the driver. Styled the same way as the pickup/dropoff location
/// pickers (dark map style, no native controls).
class RideTrackingMapWidget extends StatefulWidget {
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;
  final RideLocationModel? driverLocation;
  final List<RoutePointModel> routePoints;

  /// The planned road pickup → dropoff; while it is empty a dashed straight
  /// line stands in.
  final List<RoutePointModel> plannedRoute;

  const RideTrackingMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.driverLocation,
    this.routePoints = const [],
    this.plannedRoute = const [],
  });

  @override
  State<RideTrackingMapWidget> createState() => _RideTrackingMapWidgetState();
}

class _RideTrackingMapWidgetState extends State<RideTrackingMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  BitmapDescriptor? _taxiIcon;
  final _heading = CarHeadingTracker();

  /// The road line, converted once per route rather than on every GPS tick.
  Polyline? _roadLine;

  /// The closest the camera zooms when framing driver and pickup (~440 m).
  static const double _minFrameSpanDegrees = 0.004;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadTaxiIcon();
    _roadLine = _buildRoadLine(widget.routePoints);
    final location = widget.driverLocation;
    if (location != null) _heading.update(LatLng(location.lat, location.lng));
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
  void didUpdateWidget(covariant RideTrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged = !identical(widget.routePoints, oldWidget.routePoints);
    if (routeChanged) _roadLine = _buildRoadLine(widget.routePoints);

    final location = widget.driverLocation;
    final moved = location != null && location != oldWidget.driverLocation;
    if (moved) _heading.update(LatLng(location.lat, location.lng));
    if (moved || routeChanged) _moveCamera();
    // The planned road just loaded and no driver is on the map yet: show the
    // whole trip.
    if (widget.driverLocation == null &&
        widget.plannedRoute.length >= 2 &&
        !identical(widget.plannedRoute, oldWidget.plannedRoute)) {
      _frameTrip();
    }
  }

  void _frameTrip() {
    final controller = _mapController;
    if (controller == null) return;
    var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
    for (final p in widget.plannedRoute) {
      south = math.min(south, p.lat);
      north = math.max(north, p.lat);
      west = math.min(west, p.lng);
      east = math.max(east, p.lng);
    }
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      _frameOf(LatLng(south, west), LatLng(north, east)),
      72,
    ));
  }

  Polyline? _buildRoadLine(List<RoutePointModel> points) {
    if (points.length < 2) return null;
    return Polyline(
      polylineId: const PolylineId('driver_to_pickup'),
      points: [for (final p in points) LatLng(p.lat, p.lng)],
      color: AppColors.mapRoutePlanned,
      width: 5,
      zIndex: 1,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  void _moveCamera() {
    final controller = _mapController;
    final location = widget.driverLocation;
    if (controller == null || location == null) return;

    final driver = LatLng(location.lat, location.lng);
    if (_roadLine == null) {
      controller.animateCamera(CameraUpdate.newLatLng(driver));
      return;
    }
    final pickup = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    controller.animateCamera(CameraUpdate.newLatLngBounds(_frameOf(driver, pickup), 72));
  }

  /// The box around [a] and [b], never smaller than [_minFrameSpanDegrees]
  /// so a driver standing at the pickup doesn't zoom the map to the rooftops.
  LatLngBounds _frameOf(LatLng a, LatLng b) {
    var south = math.min(a.latitude, b.latitude);
    var north = math.max(a.latitude, b.latitude);
    var west = math.min(a.longitude, b.longitude);
    var east = math.max(a.longitude, b.longitude);
    if (north - south < _minFrameSpanDegrees) {
      final pad = (_minFrameSpanDegrees - (north - south)) / 2;
      south -= pad;
      north += pad;
    }
    if (east - west < _minFrameSpanDegrees) {
      final pad = (_minFrameSpanDegrees - (east - west)) / 2;
      west -= pad;
      east += pad;
    }
    return LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
  }

  @override
  Widget build(BuildContext context) {
    final pickupPoint = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final dropoffPoint = LatLng(widget.dropoff.latitude, widget.dropoff.longitude);
    final location = widget.driverLocation;
    final driverPoint = location != null ? LatLng(location.lat, location.lng) : null;
    final taxiIcon = _taxiIcon;
    final roadLine = _roadLine;

    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: driverPoint ?? pickupPoint, zoom: 14),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
      polylines: {
        if (widget.plannedRoute.length >= 2)
          Polyline(
            polylineId: const PolylineId('planned_route'),
            points: [for (final p in widget.plannedRoute) LatLng(p.lat, p.lng)],
            color: AppColors.textTertiary,
            width: 4,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          )
        else
          Polyline(
            polylineId: const PolylineId('pickup_dropoff'),
            points: [pickupPoint, dropoffPoint],
            color: AppColors.textTertiary,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        ?roadLine,
      },
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        if (driverPoint != null && taxiIcon != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: driverPoint,
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
