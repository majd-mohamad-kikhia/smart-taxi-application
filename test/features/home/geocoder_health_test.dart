import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/geocoder_health.dart';

void main() {
  late DateTime now;
  late GeocoderHealth health;

  setUp(() {
    now = DateTime(2026, 10, 20, 12);
    health = GeocoderHealth(now: () => now);
  });

  test('a new source is available', () {
    expect(health.isAvailable, isTrue);
    expect(health.skippedFor, Duration.zero);
  });

  test('a persistent failure closes it at once for five minutes', () {
    health.recordFailure(persistent: true);

    expect(health.isAvailable, isFalse);
    expect(health.skippedFor, GeocoderHealth.persistentCooldown);

    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(health.isAvailable, isFalse);
    expect(health.skippedFor, const Duration(seconds: 1));

    now = now.add(const Duration(seconds: 1));
    expect(health.isAvailable, isTrue);
  });

  test('plain failures close it only after two in a row, for 30 seconds', () {
    health.recordFailure(persistent: false);
    expect(health.isAvailable, isTrue);

    health.recordFailure(persistent: false);
    expect(health.isAvailable, isFalse);
    expect(health.skippedFor, GeocoderHealth.transientCooldown);

    now = now.add(const Duration(seconds: 30));
    expect(health.isAvailable, isTrue);
  });

  test('a success clears the strikes and opens the door', () {
    health.recordFailure(persistent: true);
    health.recordSuccess();
    expect(health.isAvailable, isTrue);

    health.recordFailure(persistent: false);
    expect(health.isAvailable, isTrue, reason: 'one strike again, not two');
  });

  test('after a cooldown, one more failure closes it again at once', () {
    health.recordFailure(persistent: false);
    health.recordFailure(persistent: false);
    now = now.add(const Duration(seconds: 31));
    expect(health.isAvailable, isTrue);

    health.recordFailure(persistent: false);

    expect(health.isAvailable, isFalse);
  });
}
