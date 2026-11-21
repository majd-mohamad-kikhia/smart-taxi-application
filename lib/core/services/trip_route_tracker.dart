import 'package:flutter/foundation.dart';
import '../models/driving_route_model.dart';
import '../models/route_point_model.dart';
import '../utils/route_matcher.dart';
import 'route_exception.dart';
import 'routes_provider.dart';

/// What the map shows for the leg being tracked.
class TripRouteSnapshot {
  /// The road line to draw — the same list instance until it is replaced, so
  /// a map can tell "unchanged" by identity.
  final List<RoutePointModel> line;

  /// What is left of the route for the car's latest fix; null while there is
  /// no route yet or the car has left it.
  final RouteProgress? progress;

  const TripRouteSnapshot({required this.line, required this.progress});
}

/// Follows a moving car on its way to a fixed target: the road line drawn
/// and the remaining distance/time, at the lowest cost.
///
/// Every request to the routing service costs something, so the road of a leg is
/// asked for **once** (the driver's way to the pickup, when the order is
/// accepted) and then only drawn: every GPS fix is matched onto it locally
/// ([RouteMatcher]). It is never fetched again when the car drifts off it,
/// when it ages or while the car moves. A failed request is retried a few
/// times with growing waits, then given up (the map draws a straight line).
/// A road that is already known — the trip's `planned_route` — is handed in
/// with [useRoute] and never fetched. One request at a time. One instance
/// per tracked trip.
class TripRouteTracker {
  /// First wait before a failed request is retried; it doubles each time.
  static const Duration _retryGap = Duration(seconds: 30);

  /// A leg's road is asked for at most this many times in all.
  static const int _maxAttempts = 3;

  final RoutesProvider _service;
  final DateTime Function() _now;

  DrivingRouteModel? _line;
  RouteMatcher? _matcher;
  DateTime? _lastAttemptAt;
  bool _isFetching = false;
  int _attempts = 0;
  int _generation = 0;

  TripRouteTracker(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Feeds the car's latest fix ([carLat], [carLng]) heading for
  /// ([targetLat], [targetLng]). Asks the routing service only while the leg
  /// has no road yet; completes at once otherwise.
  Future<TripRouteSnapshot> update({
    required double carLat,
    required double carLng,
    required double targetLat,
    required double targetLng,
  }) async {
    if (_canFetch) {
      await _fetch(carLat, carLng, targetLat, targetLng);
    }
    return TripRouteSnapshot(
      line: _line?.points ?? const [],
      progress: _matcher?.match(carLat, carLng),
    );
  }

  /// Uses a road that is already known, so nothing is fetched for this leg.
  void useRoute(DrivingRouteModel route) {
    _line = route;
    _matcher = RouteMatcher(route);
    _generation++;
  }

  /// Forgets the route — for when the leg changes. A request already in
  /// flight for the old leg is dropped.
  void reset() {
    _line = null;
    _matcher = null;
    _lastAttemptAt = null;
    _attempts = 0;
    _generation++;
  }

  bool get _canFetch {
    if (_matcher != null || _isFetching || _attempts >= _maxAttempts) {
      return false;
    }
    final last = _lastAttemptAt;
    if (last == null) return true;
    final wait = _retryGap * (1 << (_attempts - 1).clamp(0, 10));
    return _now().difference(last) >= wait;
  }

  Future<void> _fetch(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    _isFetching = true;
    _lastAttemptAt = _now();
    _attempts++;
    final generation = _generation;
    try {
      final route = await _service.computeRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      if (generation != _generation) return;
      _matcher = RouteMatcher(route);
      _line = route;
    } on RouteException catch (e) {
      debugPrint('TripRouteTracker: route request failed: $e');
    } finally {
      _isFetching = false;
    }
  }
}
