import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_location_model.dart';

/// Live map: pickup/dropoff pins always shown, driver pin + re-centering
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

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_styles/dark_map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  @override
  void didUpdateWidget(covariant RideTrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.driverLocation;
    if (location != null && location != oldWidget.driverLocation) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(location.lat, location.lng)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupPoint = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final dropoffPoint = LatLng(widget.dropoff.latitude, widget.dropoff.longitude);
    final location = widget.driverLocation;
    final driverPoint = location != null ? LatLng(location.lat, location.lng) : null;

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
        if (driverPoint != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: driverPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          ),
      },
    );
  }
}
