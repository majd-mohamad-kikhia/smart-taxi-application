import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Keeps a parked car from "walking" on the map.
///
/// A phone's GPS never reports exactly the same spot twice: even standing
/// still, the fixes wander by several metres, and by tens of metres in a
/// garage or between tall buildings. Shown as they are they make the car
/// drift around (and, summed, add distance that was never driven).
///
/// A fix is let through only when it moved farther than the noise from the
/// last one let through — that fix's own accuracy, at least [minJitterMeters]
/// — or when the phone reports real speed ([movingSpeed]). Measured from the
/// last accepted fix, so a slowly creeping car still gets through once it
/// has really moved. One instance per stream.
///
/// A poor fix ([poorAccuracyMeters] or worse: usually a phone falling back to
/// Wi-Fi or mobile-tower positioning when the GPS has no sky, typically with
/// a slow connection) is also dropped while a good one is less than
/// [poorFixGrace] old, so the car doesn't jump 100 m away and back.
class StationaryFixFilter {
  /// The least wander ever treated as noise, in metres.
  static const double minJitterMeters = 12;

  /// Faster than this, in m/s (~5 km/h), the car is certainly moving.
  static const double movingSpeed = 1.5;

  /// A fix this uncertain (metres) or worse is not trusted over a good one.
  static const double poorAccuracyMeters = 60;

  /// How long a good fix is kept in place of poor ones. After that the car
  /// may really be somewhere the GPS can't see (a tunnel): show what we get.
  static const Duration poorFixGrace = Duration(seconds: 30);

  Position? _last;

  /// True when [position] is a real move (or the first fix) and should be
  /// used; false when it is just GPS wander around the last accepted one.
  bool accept(Position position) {
    final last = _last;
    if (last == null) {
      _last = position;
      return true;
    }
    if (position.accuracy >= poorAccuracyMeters &&
        last.accuracy < poorAccuracyMeters &&
        position.timestamp.difference(last.timestamp) < poorFixGrace) {
      return false;
    }
    final noise = math.max(minJitterMeters, position.accuracy);
    final moved = _metersBetween(last, position);
    if (moved < noise && position.speed < movingSpeed) return false;
    _last = position;
    return true;
  }

  /// Forgets the last fix: the next one is accepted whatever it says.
  void reset() => _last = null;

  /// Haversine; a few metres of error are fine here.
  static double _metersBetween(Position a, Position b) {
    const earthRadius = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h.toDouble()));
  }
}
