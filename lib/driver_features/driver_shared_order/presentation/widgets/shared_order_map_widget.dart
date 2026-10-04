import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A still map with the order's pickup (green) and drop-off (red) pins,
/// framed so both are in view. Gestures are off: it is a preview, and it
/// sits inside a scrolling page.
class SharedOrderMapWidget extends StatefulWidget {
  final LatLng pickup;
  final LatLng dropoff;

  const SharedOrderMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  @override
  State<SharedOrderMapWidget> createState() => _SharedOrderMapWidgetState();
}

class _SharedOrderMapWidgetState extends State<SharedOrderMapWidget> {
  static const _framePadding = 48.0;

  String? _mapStyle;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  @override
  void didUpdateWidget(SharedOrderMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup || oldWidget.dropoff != widget.dropoff) {
      _frame();
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

  void _frame() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(widget.pickup.latitude, widget.dropoff.latitude),
        math.min(widget.pickup.longitude, widget.dropoff.longitude),
      ),
      northeast: LatLng(
        math.max(widget.pickup.latitude, widget.dropoff.latitude),
        math.max(widget.pickup.longitude, widget.dropoff.longitude),
      ),
    );
    _controller?.moveCamera(CameraUpdate.newLatLngBounds(bounds, _framePadding));
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: widget.pickup, zoom: 13),
      onMapCreated: (controller) {
        _controller = controller;
        // The map has no size until its first layout.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _frame();
        });
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: widget.dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
    );
  }
}
