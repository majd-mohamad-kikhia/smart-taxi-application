import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/car_heading_tracker.dart';
import '../../../../core/utils/taxi_marker_icon.dart';
import '../../data/models/ride_location_model.dart';

/// Live map: pickup/dropoff pins always shown, driver taxi + re-centering
/// once GPS starts arriving over `customer:driver_location`. Styled the
/// same way as the pickup/dropoff location pickers (dark map style, no
/// native controls).
class RideTrackingMapWidget extends StatefulWidget {
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;
  final RideLocationModel? driverLocation;

  const RideTrackingMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.driverLocation,
  });

  @override
  State<RideTrackingMapWidget> createState() => _RideTrackingMapWidgetState();
}

class _RideTrackingMapWidgetState extends State<RideTrackingMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  BitmapDescriptor? _taxiIcon;
  final _heading = CarHeadingTracker();

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadTaxiIcon();
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
    final location = widget.driverLocation;
    if (location != null && location != oldWidget.driverLocation) {
      final point = LatLng(location.lat, location.lng);
      _heading.update(point);
      _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupPoint = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final dropoffPoint = LatLng(widget.dropoff.latitude, widget.dropoff.longitude);
    final location = widget.driverLocation;
    final driverPoint = location != null ? LatLng(location.lat, location.lng) : null;
    final taxiIcon = _taxiIcon;

    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: driverPoint ?? pickupPoint, zoom: 14),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
      polylines: {
        Polyline(
          polylineId: const PolylineId('pickup_dropoff'),
          points: [pickupPoint, dropoffPoint],
          color: AppColors.textTertiary,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
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
