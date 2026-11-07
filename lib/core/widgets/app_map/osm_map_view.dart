import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:latlong2/latlong.dart' as ll;
import 'package:package_info_plus/package_info_plus.dart';
import 'app_map_controller.dart';

/// OpenStreetMap drawing of an `AppMapWidget`: the same markers, lines,
/// circles and camera callbacks, from Google-typed arguments.
class OsmMapView extends StatefulWidget {
  final g.CameraPosition initialCameraPosition;
  final ValueChanged<AppMapController>? onMapCreated;
  final Set<g.Marker> markers;
  final Set<g.Polyline> polylines;
  final Set<g.Circle> circles;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<g.CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final ValueChanged<g.LatLng>? onTap;
  final bool dark;
  final bool scrollEnabled;
  final bool zoomEnabled;

  const OsmMapView({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.polylines,
    required this.circles,
    required this.dark,
    required this.scrollEnabled,
    required this.zoomEnabled,
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
  });

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView> {
  static const Duration _idleAfter = Duration(milliseconds: 250);
  static const double _pinSize = 40;

  final osm.MapController _controller = osm.MapController();
  Timer? _idleTimer;
  bool _moving = false;
  String _userAgent = 'smart_taxi';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _userAgent = info.packageName);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _onPositionChanged(osm.MapCamera camera, bool hasGesture) {
    if (!_moving) {
      _moving = true;
      widget.onCameraMoveStarted?.call();
    }
    widget.onCameraMove?.call(
      g.CameraPosition(
        target: g.LatLng(camera.center.latitude, camera.center.longitude),
        zoom: camera.zoom,
      ),
    );
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleAfter, () {
      _moving = false;
      widget.onCameraIdle?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.initialCameraPosition;
    var flags = osm.InteractiveFlag.none;
    if (widget.scrollEnabled) {
      flags |= osm.InteractiveFlag.drag | osm.InteractiveFlag.flingAnimation;
    }
    if (widget.zoomEnabled) {
      flags |= osm.InteractiveFlag.pinchZoom |
          osm.InteractiveFlag.doubleTapZoom |
          osm.InteractiveFlag.scrollWheelZoom;
    }
    return osm.FlutterMap(
      mapController: _controller,
      options: osm.MapOptions(
        initialCenter: _latLng(start.target),
        initialZoom: start.zoom,
        minZoom: 2,
        maxZoom: 19,
        interactionOptions: osm.InteractionOptions(flags: flags),
        onMapReady: () =>
            widget.onMapCreated?.call(OsmAppMapController(_controller)),
        onPositionChanged: _onPositionChanged,
        onTap: widget.onTap == null
            ? null
            : (_, point) =>
                  widget.onTap!(g.LatLng(point.latitude, point.longitude)),
      ),
      children: [
        osm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: _userAgent,
          tileBuilder: widget.dark ? osm.darkModeTileBuilder : null,
        ),
        osm.PolylineLayer(
          polylines: [
            for (final line in widget.polylines)
              if (line.points.length >= 2)
                osm.Polyline(
                  points: [for (final p in line.points) _latLng(p)],
                  color: line.color,
                  strokeWidth: line.width.toDouble(),
                  pattern: line.patterns.isEmpty
                      ? const osm.StrokePattern.solid()
                      : osm.StrokePattern.dashed(segments: const [10, 8]),
                ),
          ],
        ),
        osm.CircleLayer(
          circles: [
            for (final circle in widget.circles)
              osm.CircleMarker(
                point: _latLng(circle.center),
                radius: circle.radius,
                useRadiusInMeter: true,
                color: circle.fillColor,
                borderColor: circle.strokeColor,
                borderStrokeWidth: circle.strokeWidth.toDouble(),
              ),
          ],
        ),
        osm.MarkerLayer(
          rotate: false,
          markers: [for (final m in widget.markers) _marker(m)],
        ),
        const osm.SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors'),
        ),
      ],
    );
  }

  osm.Marker _marker(g.Marker marker) {
    final icon = marker.icon;
    var width = _pinSize;
    var height = _pinSize;
    Widget child;
    if (icon is g.BytesMapBitmap) {
      width = icon.width ?? _pinSize;
      height = icon.height ?? icon.width ?? _pinSize;
      child = Image.memory(icon.byteData, width: width, height: height);
    } else {
      final hue = _hueOf(icon);
      child = Icon(
        Icons.location_on,
        size: _pinSize,
        color: HSVColor.fromAHSV(1, hue % 360, 0.85, 0.9).toColor(),
      );
    }
    if (marker.rotation != 0) {
      child = Transform.rotate(
        angle: marker.rotation * math.pi / 180,
        child: child,
      );
    }
    final onTap = marker.onTap;
    if (onTap != null) child = GestureDetector(onTap: onTap, child: child);
    // Google anchors a marker by a point of its image; a pin's tip is
    // bottom-centre, a car's middle is the centre.
    final anchor = marker.anchor;
    return osm.Marker(
      point: _latLng(marker.position),
      width: width,
      height: height,
      rotate: false,
      alignment: Alignment((0.5 - anchor.dx) * 2, (0.5 - anchor.dy) * 2),
      child: child,
    );
  }

  /// The colour of a default Google pin, read from its JSON form
  /// (`['defaultMarker', hue]`); red when it has none.
  double _hueOf(g.BitmapDescriptor icon) {
    final json = icon.toJson();
    if (json is List && json.length > 1 && json[1] is num) {
      return (json[1] as num).toDouble();
    }
    return 0;
  }

  ll.LatLng _latLng(g.LatLng p) => ll.LatLng(p.latitude, p.longitude);
}
