import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/utils/stationary_fix_filter.dart';

/// ~[northMeters] north of a base point in Latitakia.
Position _fix({
  double northMeters = 0,
  double accuracy = 5,
  double speed = 0,
  int seconds = 0,
}) => Position(
  latitude: 35.5 + northMeters / 111320,
  longitude: 35.8,
  timestamp: DateTime(2026, 11, 10, 12).add(Duration(seconds: seconds)),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: speed,
  speedAccuracy: 0,
);

void main() {
  late StationaryFixFilter filter;

  setUp(() => filter = StationaryFixFilter());

  test('the first fix always goes through', () {
    expect(filter.accept(_fix()), isTrue);
  });

  test('a parked car wandering a few metres stays put', () {
    filter.accept(_fix());
    for (final wander in [4.0, -6.0, 9.0, -3.0, 11.0]) {
      expect(filter.accept(_fix(northMeters: wander)), isFalse);
    }
  });

  test('a poor fix may wander as far as its own accuracy', () {
    filter.accept(_fix());
    expect(filter.accept(_fix(northMeters: 35, accuracy: 55)), isFalse);
    expect(filter.accept(_fix(northMeters: 80, accuracy: 55)), isTrue);
  });

  test('a poor fix 100 m away does not replace a good one', () {
    filter.accept(_fix(accuracy: 8));
    expect(filter.accept(_fix(northMeters: 100, accuracy: 80, seconds: 5)), isFalse);
    // The good one is still the reference: the car coming back is just noise.
    expect(filter.accept(_fix(northMeters: 3, accuracy: 8, seconds: 10)), isFalse);
  });

  test('poor fixes are shown once no good one has come for a while', () {
    filter.accept(_fix(accuracy: 8));
    expect(filter.accept(_fix(northMeters: 200, accuracy: 90, seconds: 45)), isTrue);
  });

  test('a real move gets through', () {
    filter.accept(_fix());
    expect(filter.accept(_fix(northMeters: 30)), isTrue);
  });

  test('a car creeping along is measured from the last accepted fix', () {
    filter.accept(_fix());
    // 8 m each: the first is noise, the second is 16 m from the start.
    expect(filter.accept(_fix(northMeters: 8)), isFalse);
    expect(filter.accept(_fix(northMeters: 16)), isTrue);
    expect(filter.accept(_fix(northMeters: 24)), isFalse);
  });

  test('real speed passes even for a short hop', () {
    filter.accept(_fix());
    expect(filter.accept(_fix(northMeters: 4, speed: 8)), isTrue);
  });

  test('a reset accepts the next fix whatever it says', () {
    filter.accept(_fix());
    filter.reset();
    expect(filter.accept(_fix(northMeters: 1)), isTrue);
  });
}
