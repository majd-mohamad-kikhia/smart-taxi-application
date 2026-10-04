import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Derives which way a tracked car is facing from its successive GPS fixes
/// (the backend sends no heading). The last heading is kept while the car
/// is stationary or the fix only jitters, so the icon doesn't spin in place.
class CarHeadingTracker {
  /// Moves shorter than this are treated as GPS noise.
  static const double _minMoveMeters = 3;
  static const double _metersPerDegree = 111320;

  LatLng? _last;
  double _bearing = 0;

  /// Degrees clockwise from north, as expected by `Marker.rotation`.
  double get bearing => _bearing;

  void update(LatLng position) {
    final last = _last;
    if (last == null) {
      _last = position;
      return;
    }

    final dy = (position.latitude - last.latitude) * _metersPerDegree;
    final dx = (position.longitude - last.longitude) *
        _metersPerDegree *
        math.cos(last.latitude * math.pi / 180);
    if (math.sqrt(dx * dx + dy * dy) < _minMoveMeters) return;

    _bearing = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
    _last = position;
  }
}
