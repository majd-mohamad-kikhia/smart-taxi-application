import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Static map centered on the ride's pickup point — no live tracking here,
/// just "go to this pin" for the driver who just accepted the ride. Styled
/// the same way as the pickup/dropoff location pickers (dark map style,
/// no native controls).
class DriverPickupMapWidget extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;

  const DriverPickupMapWidget({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
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
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_styles/dark_map_style.json');
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
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      },
    );
  }
}
