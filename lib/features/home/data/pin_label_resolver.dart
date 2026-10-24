import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/geo/geo_exception.dart';

/// Asks our server for the label under a pin: null when it has none.
typedef ReverseLabelLookup = Future<String?> Function(double lat, double lng);

/// Names the spot under a pin — the one place the app does it, so every
/// screen that needs a pin label (the map pick mode, the location picker, the
/// order flow's default pickup, GPS button and resets) spends the same.
///
/// A pin is named only when asked for (callers ask on camera idle, never while
/// the camera moves). A spot named before (same coordinates to 4 decimals) or
/// within [reuseRadiusMeters] of one named recently takes that label and sends
/// no request. Labels live in memory only: Google's address text is never
/// written to the device.
class PinLabelResolver {
  /// A pin closer than this to a labeled one takes its label.
  static const double reuseRadiusMeters = 25;

  static const int _cacheSize = 100;

  /// The server allows one label request per 2 seconds per customer (429
  /// otherwise): requests are spaced by at least this.
  static const Duration defaultMinGap = Duration(seconds: 2);

  final ReverseLabelLookup _lookup;
  final Duration _minGap;
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// Spots named recently, by rounded coordinates, least recently used first.
  final LinkedHashMap<String, _NamedSpot> _cache = LinkedHashMap();
  final Map<String, Future<String?>> _inFlight = {};

  int _requests = 0;

  /// Why the last lookup gave no label (for the debug build to show).
  String? lastFailure;

  PinLabelResolver(this._lookup, {Duration minGap = defaultMinGap})
    : _minGap = minGap;

  /// How many reverse-label requests were sent since the app started.
  int get requestCount => _requests;

  /// The label for ([latitude], [longitude]), or null when none is found
  /// (a failure just leaves the address unset). [reason] says what asked, for
  /// the debug log.
  Future<String?> resolve(
    double latitude,
    double longitude, {
    String reason = 'unspecified',
  }) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      _log(reason, 'skipped (<25m)', 0);
      return cached.label;
    }

    final near = _nearest(latitude, longitude);
    if (near != null) {
      _cache.remove(near.key);
      _cache[near.key] = near.spot;
      _log(reason, 'skipped (<25m)', near.meters);
      return near.spot.label;
    }

    final running = _inFlight[key];
    if (running != null) {
      _log(reason, 'skipped (same lookup in flight)', 0);
      return running;
    }

    _requests++;
    _log(reason, 'requested', _nearestDistance(latitude, longitude));
    final lookup = _lookUp(key, latitude, longitude);
    _inFlight[key] = lookup;
    try {
      return await lookup;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<String?> _lookUp(String key, double latitude, double longitude) async {
    try {
      await _waitForSlot();
      final label = await _lookup(latitude, longitude);
      lastFailure = label == null ? 'the server sent no label' : null;
      if (label != null) {
        _cache[key] = _NamedSpot(latitude, longitude, label);
        while (_cache.length > _cacheSize) {
          _cache.remove(_cache.keys.first);
        }
      }
      return label;
    } on GeoException catch (e) {
      lastFailure = e.detail ?? e.failure.name;
      debugPrint('PinLabelResolver: could not name the pin: $e');
      return null;
    }
  }

  /// Two spots named within 2 seconds (the From and To fields, a pin that
  /// settles twice) would make the server refuse the second: it waits its
  /// turn instead, so it still gets its label.
  Future<void> _waitForSlot() async {
    final now = DateTime.now();
    final slot = _nextSlot.isAfter(now) ? _nextSlot : now;
    _nextSlot = slot.add(_minGap);
    final wait = slot.difference(now);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  ({String key, _NamedSpot spot, double meters})? _nearest(
    double latitude,
    double longitude,
  ) {
    ({String key, _NamedSpot spot, double meters})? best;
    for (final entry in _cache.entries) {
      final spot = entry.value;
      final d = distanceMeters(spot.lat, spot.lng, latitude, longitude);
      if (d < reuseRadiusMeters && (best == null || d < best.meters)) {
        best = (key: entry.key, spot: spot, meters: d);
      }
    }
    return best;
  }

  /// Distance to the closest labeled spot, or null when none is known — for
  /// the log only.
  double? _nearestDistance(double latitude, double longitude) {
    double? best;
    for (final spot in _cache.values) {
      final d = distanceMeters(spot.lat, spot.lng, latitude, longitude);
      if (best == null || d < best) best = d;
    }
    return best;
  }

  /// Straight-line distance between two points in meters (haversine).
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(lat2 - lat1);
    final dLng = radians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(a));
  }

  /// Never logs a key, a URL or an address.
  void _log(String reason, String decision, double? meters) {
    if (!kDebugMode) return;
    final distance = meters == null
        ? 'no labeled point yet'
        : '${meters.round()} m';
    debugPrint('[pin label] $reason | $decision | $distance');
  }
}

/// A spot that was named: where it is and what it was called.
class _NamedSpot {
  final double lat;
  final double lng;
  final String label;

  const _NamedSpot(this.lat, this.lng, this.label);
}
