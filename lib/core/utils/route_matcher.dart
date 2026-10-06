import 'dart:math' as math;
import 'dart:typed_data';
import '../models/driving_route_model.dart';

/// How far along a route a car is, and what is left of it.
class RouteProgress {
  final double remainingMeters;
  final double remainingSeconds;

  const RouteProgress({
    required this.remainingMeters,
    required this.remainingSeconds,
  });
}

/// Snaps GPS fixes onto a [DrivingRouteModel] to get the remaining distance
/// and travel time without asking the routing service again.
///
/// The route is flattened once into a local meters plane (typed arrays, with
/// cumulative lengths), so each fix costs a few multiplications per segment
/// and no allocation. Fixes advance along the route, so the search starts at
/// the last matched segment and only widens to the whole route when the car
/// isn't found near it.
class RouteMatcher {
  /// Farther than this from the line, the car is off the route (took another
  /// road) and the route no longer describes what is left.
  static const double maxOffRouteMeters = 60;

  /// Segments searched ahead of the last match before scanning everything.
  static const int _window = 30;

  static const double _metersPerDegreeLat = 111320;

  final DrivingRouteModel route;
  final double _lat0;
  final double _lng0;
  final double _metersPerDegreeLng;
  final int _segments;
  final Float64List _x;
  final Float64List _y;

  /// Planar length of the route up to vertex `i`.
  final Float64List _along;
  int _cursor = 0;

  // Result slots of [_scan], kept as fields so a scan allocates nothing.
  int _bestSegment = 0;
  double _bestFraction = 0;
  double _bestDistanceSq = double.infinity;

  factory RouteMatcher(DrivingRouteModel route) {
    final points = route.points;
    final lat0 = points.isEmpty ? 0.0 : points.first.lat;
    final lng0 = points.isEmpty ? 0.0 : points.first.lng;
    final metersPerDegreeLng =
        _metersPerDegreeLat * math.cos(lat0 * math.pi / 180);

    final x = Float64List(points.length);
    final y = Float64List(points.length);
    final along = Float64List(points.length);
    for (var i = 0; i < points.length; i++) {
      x[i] = (points[i].lng - lng0) * metersPerDegreeLng;
      y[i] = (points[i].lat - lat0) * _metersPerDegreeLat;
      if (i > 0) {
        along[i] = along[i - 1] + math.sqrt(_sq(x[i] - x[i - 1]) + _sq(y[i] - y[i - 1]));
      }
    }
    return RouteMatcher._(route, lat0, lng0, metersPerDegreeLng, x, y, along);
  }

  RouteMatcher._(
    this.route,
    this._lat0,
    this._lng0,
    this._metersPerDegreeLng,
    this._x,
    this._y,
    this._along,
  ) : _segments = math.max(0, _x.length - 1);

  static double _sq(double v) => v * v;

  /// The remaining distance/time for a car at ([lat], [lng]), or null when
  /// the car is off the route (or the route has no line).
  RouteProgress? match(double lat, double lng) {
    if (_segments == 0) return null;
    final px = (lng - _lng0) * _metersPerDegreeLng;
    final py = (lat - _lat0) * _metersPerDegreeLat;
    const maxSq = maxOffRouteMeters * maxOffRouteMeters;

    _scan(px, py, math.max(0, _cursor - 2), math.min(_segments, _cursor + _window));
    if (_bestDistanceSq > maxSq) _scan(px, py, 0, _segments);
    if (_bestDistanceSq > maxSq) return null;

    _cursor = _bestSegment;
    final total = _along[_segments];
    final segmentLength = _along[_bestSegment + 1] - _along[_bestSegment];
    final travelled = _along[_bestSegment] + _bestFraction * segmentLength;
    final remaining = total <= 0 ? 0.0 : (1 - travelled / total).clamp(0.0, 1.0);

    // The service's own road distance/time, scaled by what is left, so the
    // figures start exactly at what it computed and shrink as the car moves.
    return RouteProgress(
      remainingMeters: route.distanceMeters * remaining,
      remainingSeconds: route.durationSeconds * remaining,
    );
  }

  /// Finds the segment in [from, to) closest to (px, py) into the `_best*`
  /// slots.
  void _scan(double px, double py, int from, int to) {
    _bestDistanceSq = double.infinity;
    for (var i = from; i < to; i++) {
      final ax = _x[i];
      final ay = _y[i];
      final dx = _x[i + 1] - ax;
      final dy = _y[i + 1] - ay;
      final lengthSq = dx * dx + dy * dy;
      final fraction = lengthSq == 0
          ? 0.0
          : (((px - ax) * dx + (py - ay) * dy) / lengthSq).clamp(0.0, 1.0);
      final distanceSq = _sq(px - (ax + fraction * dx)) + _sq(py - (ay + fraction * dy));
      if (distanceSq < _bestDistanceSq) {
        _bestDistanceSq = distanceSq;
        _bestSegment = i;
        _bestFraction = fraction;
      }
    }
  }
}
