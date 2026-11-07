import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/map_backend.dart';
import 'app_map_controller.dart';
import 'osm_map_view.dart';

/// The app's map. Draws what the server says ([MapBackend.useOsm]): Google
/// Maps, or OpenStreetMap when the manager chose it. Even on Google, a map
/// that has not opened 15 seconds after it appeared moves to OpenStreetMap.
/// Same arguments for both — so a screen
/// builds its markers, lines and camera moves once. Options that only make
/// sense on Google's map (my-location, toolbar, buildings, tilt, padding)
/// are ignored on OpenStreetMap.
class AppMapWidget extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final ValueChanged<AppMapController>? onMapCreated;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final ValueChanged<LatLng>? onTap;

  /// Gestures the map claims inside a scrolling parent (Google only; the
  /// OpenStreetMap map always claims its own).
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The Google map style JSON; non-null means the dark theme.
  final String? style;
  final EdgeInsets padding;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final bool buildingsEnabled;

  const AppMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.style,
    this.padding = EdgeInsets.zero,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
    this.zoomControlsEnabled = true,
    this.mapToolbarEnabled = true,
    this.compassEnabled = true,
    this.buildingsEnabled = true,
  });

  @override
  State<AppMapWidget> createState() => _AppMapWidgetState();
}

class _AppMapWidgetState extends State<AppMapWidget> {
  /// How long Google's map gets to show something before OpenStreetMap
  /// takes over.
  static const Duration _googleTimeout = Duration(seconds: 15);

  Timer? _timer;
  AppMapController? _googleController;
  CameraPosition? _lastCamera;
  /// Google's map failed to open here; OpenStreetMap is shown instead.
  bool _googleFailed = false;

  /// The manager chose OpenStreetMap, or Google's map failed here.
  bool get _useOsm => MapBackend.useOsm.value || _googleFailed;

  @override
  void initState() {
    super.initState();
    MapBackend.useOsm.addListener(_onProviderChanged);
    _watchGoogle();
  }

  @override
  void dispose() {
    MapBackend.useOsm.removeListener(_onProviderChanged);
    _timer?.cancel();
    super.dispose();
  }

  /// The server changed the map: swap now, and watch Google again if it is
  /// the one drawn.
  void _onProviderChanged() {
    _googleController = null;
    _googleFailed = false;
    _watchGoogle();
    if (mounted) setState(() {});
  }

  void _watchGoogle() {
    _timer?.cancel();
    if (!MapBackend.useOsm.value) {
      _timer = Timer(_googleTimeout, _checkGoogle);
    }
  }

  /// Google's plugin never reports a bad key, so after [_googleTimeout] the
  /// map is judged by what it shows: no map view at all, or a picture with
  /// no map in it (one flat colour), moves everything to OpenStreetMap.
  Future<void> _checkGoogle() async {
    if (!mounted || _useOsm) return;
    final controller = _googleController;
    var failed = controller == null;
    if (controller != null) {
      try {
        final shot = await controller.takeSnapshot();
        if (shot != null) failed = await _isBlank(shot);
      } catch (_) {
        // Can't tell: keep Google.
      }
    }
    if (!mounted || !failed) return;
    debugPrint('Map: Google did not open in 15s, using OpenStreetMap');
    setState(() => _googleFailed = true);
  }

  /// A map with tiles has many colours; an unloaded one is a single grey.
  Future<bool> _isBlank(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png, targetWidth: 48);
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData();
    if (data == null) return false;
    final colors = <int>{};
    for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
      colors.add(
        (data.getUint8(i) >> 4) << 8 |
            (data.getUint8(i + 1) >> 4) << 4 |
            (data.getUint8(i + 2) >> 4),
      );
    }
    return colors.length <= 3;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (_useOsm) {
      return OsmMapView(
        // Where Google's camera was, so the swap doesn't move the map.
        initialCameraPosition: _lastCamera ?? w.initialCameraPosition,
        onMapCreated: w.onMapCreated,
        markers: w.markers,
        polylines: w.polylines,
        circles: w.circles,
        onCameraMoveStarted: w.onCameraMoveStarted,
        onCameraMove: (position) {
          _lastCamera = position;
          w.onCameraMove?.call(position);
        },
        onCameraIdle: w.onCameraIdle,
        onTap: w.onTap,
        dark: w.style != null,
        scrollEnabled: w.scrollGesturesEnabled,
        zoomEnabled: w.zoomGesturesEnabled,
      );
    }
    return GoogleMap(
      initialCameraPosition: w.initialCameraPosition,
      onMapCreated: (controller) {
        final wrapped = GoogleAppMapController(controller);
        _googleController = wrapped;
        w.onMapCreated?.call(wrapped);
      },
      markers: w.markers,
      polylines: w.polylines,
      circles: w.circles,
      onCameraMoveStarted: w.onCameraMoveStarted,
      onCameraMove: (position) {
        _lastCamera = position;
        w.onCameraMove?.call(position);
      },
      onCameraIdle: w.onCameraIdle,
      onTap: w.onTap,
      gestureRecognizers: w.gestureRecognizers,
      style: w.style,
      padding: w.padding,
      scrollGesturesEnabled: w.scrollGesturesEnabled,
      zoomGesturesEnabled: w.zoomGesturesEnabled,
      rotateGesturesEnabled: w.rotateGesturesEnabled,
      tiltGesturesEnabled: w.tiltGesturesEnabled,
      myLocationEnabled: w.myLocationEnabled,
      myLocationButtonEnabled: w.myLocationButtonEnabled,
      zoomControlsEnabled: w.zoomControlsEnabled,
      mapToolbarEnabled: w.mapToolbarEnabled,
      compassEnabled: w.compassEnabled,
      buildingsEnabled: w.buildingsEnabled,
    );
  }
}
