import 'package:flutter/foundation.dart';
import '../models/route_point_model.dart';
import '../models/driving_route_model.dart';
import 'google_routes_service.dart';
import 'route_service.dart';

/// Loads the planned road route for a trip once and keeps it fixed — it is
/// never trimmed or re-routed while the car moves (the driven path is
/// drawn separately). One instance per screen/cubit.
///
/// [load] is safe to call repeatedly: it returns the cached route once
/// there is one, and while there isn't (first request in flight, or it
/// failed) it retries at most every [_retryInterval].
class PlannedRouteLoader {
  static const _retryInterval = Duration(seconds: 10);

  final RouteService _routeService;

  /// The road from Google Routes, tried first; [_routeService] (OSRM) stands
  /// in when Google can't answer.
  final GoogleRoutesService? _google;

  List<RoutePointModel> _route = const [];
  bool _isLoading = false;
  DateTime? _lastAttemptAt;
  int _generation = 0;

  PlannedRouteLoader(this._routeService, {GoogleRoutesService? google})
    : _google = google;

  /// The planned route from ([fromLat], [fromLng]) to ([toLat], [toLng]),
  /// or an empty list while it isn't available yet.
  Future<List<RoutePointModel>> load({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (_route.isNotEmpty || _isLoading) return _route;
    final last = _lastAttemptAt;
    if (last != null && DateTime.now().difference(last) < _retryInterval) {
      return _route;
    }

    _isLoading = true;
    _lastAttemptAt = DateTime.now();
    final generation = _generation;
    try {
      final route = await _fetch(fromLat, fromLng, toLat, toLng);
      if (route.length >= 2 && generation == _generation) _route = route;
    } on RouteException catch (e) {
      debugPrint('PlannedRouteLoader: route request failed: $e');
    } finally {
      _isLoading = false;
    }
    return _route;
  }

  Future<List<RoutePointModel>> _fetch(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    final google = _google;
    if (google != null) {
      try {
        final DrivingRouteModel route = await google.computeRoute(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
        if (route.points.length >= 2) return route.points;
      } on RouteException catch (e) {
        debugPrint('PlannedRouteLoader: Google route failed, using OSRM: $e');
      }
    }
    return _routeService.getRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  /// Forgets the cached route — for when the trip's points change. A
  /// request already in flight for the old points is dropped.
  void reset() {
    _route = const [];
    _lastAttemptAt = null;
    _generation++;
  }
}
