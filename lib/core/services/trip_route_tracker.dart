import 'package:flutter/foundation.dart';
import '../models/driving_route_model.dart';
import '../models/route_point_model.dart';
import '../utils/route_matcher.dart';
import 'google_routes_service.dart';
import 'route_service.dart' show RouteException;

/// What the map shows for the leg being tracked.
class TripRouteSnapshot {
  /// The road line to draw — the same list instance until it is replaced, so
  /// a map can tell "unchanged" by identity.
  final List<RoutePointModel> line;

  /// What is left of the route for the car's latest fix; null while there is
  /// no route yet or the car is off it and a new one is still loading.
  final RouteProgress? progress;

  const TripRouteSnapshot({required this.line, required this.progress});
}

/// Follows a moving car on its way to a fixed target and keeps the road
/// line and the remaining distance/time up to date at the lowest cost.
///
/// Calls to the routing service are rare: the route is fetched once, and
/// every GPS fix after that is matched onto it locally ([RouteMatcher]). It
/// is fetched again only when the car leaves the route (took another road),
/// or when the route has aged enough for traffic to have changed — and never
/// more often than [_minFetchGap], even after a failure. One request at a
/// time. One instance per tracked trip.
class TripRouteTracker {
  /// A route older than this is refreshed for current traffic…
  static const Duration _staleAfter = Duration(minutes: 3);

  /// …unless the car is this close to the target (nothing left to change).
  static const double _noRefreshBelowMeters = 1000;

  /// Minimum time between two requests (also the retry interval).
  static const Duration _minFetchGap = Duration(seconds: 15);

  final GoogleRoutesService _service;
  final DateTime Function() _now;

  DrivingRouteModel? _line;
  RouteMatcher? _matcher;
  DateTime? _matcherFetchedAt;
  DateTime? _lastAttemptAt;
  bool _isFetching = false;
  int _generation = 0;

  TripRouteTracker(this._service, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// Feeds the car's latest fix ([carLat], [carLng]) heading for
  /// ([targetLat], [targetLng]).
  ///
  /// With [keepLine] the drawn line stays the first route fetched and only
  /// the arrival estimate follows later routes (the planned line of a trip
  /// in progress); otherwise the line is replaced by every new route (the
  /// driver heading to the pickup).
  ///
  /// Completes at once unless this call is the one that fetches.
  Future<TripRouteSnapshot> update({
    required double carLat,
    required double carLng,
    required double targetLat,
    required double targetLng,
    bool keepLine = false,
  }) async {
    var progress = _matcher?.match(carLat, carLng);
    if (_needsFetch(progress)) {
      await _fetch(carLat, carLng, targetLat, targetLng, keepLine);
      progress = _matcher?.match(carLat, carLng);
    }
    return TripRouteSnapshot(line: _line?.points ?? const [], progress: progress);
  }

  /// Forgets the route — for when the leg changes. A request already in
  /// flight for the old leg is dropped.
  void reset() {
    _line = null;
    _matcher = null;
    _matcherFetchedAt = null;
    _lastAttemptAt = null;
    _generation++;
  }

  bool _needsFetch(RouteProgress? progress) {
    if (_isFetching) return false;
    final last = _lastAttemptAt;
    if (last != null && _now().difference(last) < _minFetchGap) return false;
    if (_matcher == null || progress == null) return true;

    final fetchedAt = _matcherFetchedAt;
    return fetchedAt != null &&
        _now().difference(fetchedAt) > _staleAfter &&
        progress.remainingMeters > _noRefreshBelowMeters;
  }

  Future<void> _fetch(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    bool keepLine,
  ) async {
    _isFetching = true;
    _lastAttemptAt = _now();
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
      _matcherFetchedAt = _now();
      if (!keepLine || _line == null) _line = route;
    } on RouteException catch (e) {
      debugPrint('TripRouteTracker: route request failed: $e');
    } finally {
      _isFetching = false;
    }
  }
}
