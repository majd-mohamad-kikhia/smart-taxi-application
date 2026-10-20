/// Remembers whether a geocoding source is worth asking right now — a circuit
/// breaker, so a source that keeps failing is skipped instead of making
/// every search wait for its timeout first.
///
/// A failure that will not clear soon (a refused or over-quota key) opens it
/// at once for [persistentCooldown]. Plain trouble (a dropped connection, a
/// slow answer) opens it for [transientCooldown] after
/// [transientFailuresBeforeOpening] in a row. When the cooldown ends the
/// source is asked again; one more failure closes the door again, and a
/// success clears everything.
class GeocoderHealth {
  static const int transientFailuresBeforeOpening = 2;
  static const Duration transientCooldown = Duration(seconds: 30);
  static const Duration persistentCooldown = Duration(minutes: 5);

  final DateTime Function() _now;

  int _failuresInARow = 0;
  DateTime? _skipUntil;

  /// [now] exists for tests.
  GeocoderHealth({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Whether the source should be asked now.
  bool get isAvailable {
    final until = _skipUntil;
    return until == null || !_now().isBefore(until);
  }

  /// How much longer the source is left alone; zero when it is available.
  Duration get skippedFor {
    final until = _skipUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  void recordSuccess() {
    _failuresInARow = 0;
    _skipUntil = null;
  }

  /// The source failed; [persistent] says the cause will not go away soon.
  void recordFailure({required bool persistent}) {
    _failuresInARow++;
    if (persistent) {
      _skipUntil = _now().add(persistentCooldown);
    } else if (_failuresInARow >= transientFailuresBeforeOpening) {
      _skipUntil = _now().add(transientCooldown);
    }
  }
}
