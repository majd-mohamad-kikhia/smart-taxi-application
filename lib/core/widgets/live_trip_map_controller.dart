import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_controls_widget.dart';

/// How the camera looks at the trip.
enum TripMapView {
  /// Straight down, north at the top.
  topDown,

  /// Tilted, turned to face where the car is heading.
  angled,
}

/// Drives a [LiveTripMapWidget] from outside it, so its zoom and move buttons
/// can sit anywhere on the screen (e.g. in the bottom panel).
///
/// Moving the view with [nudge] stops the camera following the car
/// ([isFollowing] turns false) until [recenter] is used. Zooming keeps it
/// following. In the angled view the screen is locked on the car (the map
/// widget turns off its gestures and 3D buildings). [setView] switches between the top-down and the angled look.
/// Listeners are told when [isFollowing] or [view] changes.
class LiveTripMapController extends ChangeNotifier {
  /// How far one arrow press moves the view, in logical pixels.
  static const double _nudgeStep = 90;

  /// One tick of a held button (about every 16 ms): a small move, applied
  /// without animation so holding is smooth.
  static const double _heldNudgeStep = 6;
  static const double _heldZoomStep = 0.03;

  static const double _angledTilt = 60;

  /// The angled look is only useful close to the road; it starts at least this close.
  static const double _angledMinZoom = 17;

  GoogleMapController? _map;
  LatLng? _car;
  double _carBearing = 0;
  double _zoom = 15;
  bool _following = true;
  TripMapView _view = TripMapView.topDown;

  bool get isFollowing => _following;

  TripMapView get view => _view;

  /// Set by the map when it is created and as the car moves.
  void attach(GoogleMapController map) => _map = map;

  void updateCar(LatLng? car, [double bearing = 0]) {
    _car = car;
    _carBearing = bearing;
  }

  /// The map reports its camera as it moves, so [follow] can keep the zoom.
  void cameraMoved(CameraPosition position) => _zoom = position.zoom;

  void zoomIn() => _map?.animateCamera(CameraUpdate.zoomIn());

  void zoomOut() => _map?.animateCamera(CameraUpdate.zoomOut());

  void nudge(MapNudge nudge) {
    final step = nudge.direction * _nudgeStep;
    _map?.animateCamera(CameraUpdate.scrollBy(step.dx, step.dy));
    _setFollowing(false);
  }

  void zoomInHeld() => _map?.moveCamera(CameraUpdate.zoomBy(_heldZoomStep));

  void zoomOutHeld() => _map?.moveCamera(CameraUpdate.zoomBy(-_heldZoomStep));

  void nudgeHeld(MapNudge nudge) {
    final step = nudge.direction * _heldNudgeStep;
    _map?.moveCamera(CameraUpdate.scrollBy(step.dx, step.dy));
  }

  void setView(TripMapView view) {
    if (_view == view) return;
    _view = view;
    _following = true;
    if (view == TripMapView.angled) _zoom = math.max(_zoom, _angledMinZoom);
    notifyListeners();
    follow();
  }

  void recenter() {
    follow();
    _setFollowing(true);
  }

  /// Puts the camera on the car the way the current [view] wants it.
  void follow() {
    final map = _map;
    final car = _car;
    if (map == null || car == null) return;
    if (_view == TripMapView.topDown) {
      map.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: car, zoom: _zoom)),
      );
      return;
    }
    map.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: car,
          zoom: _zoom,
          tilt: _angledTilt,
          bearing: _carBearing,
        ),
      ),
    );
  }

  void _setFollowing(bool value) {
    if (_following == value) return;
    _following = value;
    notifyListeners();
  }
}
