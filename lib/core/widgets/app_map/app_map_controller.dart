import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

/// What the app asks of a map's camera, whichever map draws it.
abstract class AppMapController {
  Future<void> animateCamera(CameraUpdate update);
  Future<void> moveCamera(CameraUpdate update);

  /// A picture of what the map shows now; null when it can't take one (the
  /// OpenStreetMap map, or a map that isn't ready).
  Future<Uint8List?> takeSnapshot();

  /// Releases the map's native resources; the map closes with its screen.
  void dispose();
}

class GoogleAppMapController implements AppMapController {
  final GoogleMapController _controller;

  const GoogleAppMapController(this._controller);

  @override
  Future<void> animateCamera(CameraUpdate update) =>
      _controller.animateCamera(update);

  @override
  Future<void> moveCamera(CameraUpdate update) =>
      _controller.moveCamera(update);

  @override
  Future<Uint8List?> takeSnapshot() => _controller.takeSnapshot();

  @override
  void dispose() => _controller.dispose();
}

/// Runs Google's [CameraUpdate]s on an OpenStreetMap map, by reading their
/// JSON form. Animated moves jump straight to the target.
class OsmAppMapController implements AppMapController {
  static const double _maxFitZoom = 17;

  final osm.MapController map;

  OsmAppMapController(this.map);

  @override
  Future<Uint8List?> takeSnapshot() async => null;

  // The widget owns and disposes the [map] controller.
  @override
  void dispose() {}

  @override
  Future<void> animateCamera(CameraUpdate update) async => _apply(update);

  @override
  Future<void> moveCamera(CameraUpdate update) async => _apply(update);

  void _apply(CameraUpdate update) {
    final json = update.toJson();
    if (json is! List || json.isEmpty) return;
    final camera = map.camera;
    switch (json[0]) {
      case 'newLatLng':
        map.move(_point(json[1]), camera.zoom);
      case 'newLatLngZoom':
        map.move(_point(json[1]), (json[2] as num).toDouble());
      case 'newCameraPosition':
        final position = json[1] as Map;
        map.move(
          _point(position['target']),
          (position['zoom'] as num?)?.toDouble() ?? camera.zoom,
        );
      case 'newLatLngBounds':
        final corners = json[1] as List;
        map.fitCamera(
          osm.CameraFit.bounds(
            bounds: osm.LatLngBounds(_point(corners[0]), _point(corners[1])),
            padding: EdgeInsets.all((json[2] as num).toDouble()),
            maxZoom: _maxFitZoom,
          ),
        );
      case 'zoomIn':
        map.move(camera.center, camera.zoom + 1);
      case 'zoomOut':
        map.move(camera.center, camera.zoom - 1);
      case 'zoomBy':
        map.move(camera.center, camera.zoom + (json[1] as num).toDouble());
      case 'zoomTo':
        map.move(camera.center, (json[1] as num).toDouble());
      case 'scrollBy':
        final centerPx = camera.projectAtZoom(camera.center);
        map.move(
          camera.unprojectAtZoom(
            centerPx + Offset((json[1] as num).toDouble(), (json[2] as num).toDouble()),
          ),
          camera.zoom,
        );
    }
  }

  ll.LatLng _point(Object? json) {
    final pair = json as List;
    return ll.LatLng(
      math.max(-90, math.min(90, (pair[0] as num).toDouble())),
      (pair[1] as num).toDouble(),
    );
  }
}
