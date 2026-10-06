import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/driving_route_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/utils/route_matcher.dart';

/// A straight road going north along longitude 36: 0.01° of latitude is
/// ~1113 m, and the service says the whole 0.03° (~3340 m) takes 600 s.
const _road = DrivingRouteModel(
  points: [
    RoutePointModel(35.00, 36),
    RoutePointModel(35.01, 36),
    RoutePointModel(35.02, 36),
    RoutePointModel(35.03, 36),
  ],
  distanceMeters: 3000,
  durationSeconds: 600,
);

void main() {
  test('at the start everything is left, at the end nothing', () {
    final matcher = RouteMatcher(_road);

    final start = matcher.match(35.00, 36)!;
    expect(start.remainingMeters, closeTo(3000, 0.01));
    expect(start.remainingSeconds, closeTo(600, 0.01));

    final end = matcher.match(35.03, 36)!;
    expect(end.remainingMeters, closeTo(0, 0.01));
    expect(end.remainingSeconds, closeTo(0, 0.01));
  });

  test('halfway leaves half of the distance and of the time', () {
    final progress = RouteMatcher(_road).match(35.015, 36)!;

    expect(progress.remainingMeters, closeTo(1500, 1));
    expect(progress.remainingSeconds, closeTo(300, 1));
  });

  test('a fix a few meters beside the road still matches it', () {
    final progress = RouteMatcher(_road).match(35.015, 36.0003)!;

    expect(progress, isNotNull);
    expect(progress.remainingMeters, closeTo(1500, 1));
  });

  test('a fix far from the road is off the route', () {
    expect(RouteMatcher(_road).match(35.015, 36.01), isNull);
  });

  test('driving on keeps shrinking the remainder', () {
    final matcher = RouteMatcher(_road);
    final fixes = [35.002, 35.008, 35.014, 35.021, 35.027];

    final remaining = [for (final lat in fixes) matcher.match(lat, 36)!.remainingMeters];

    expect(remaining, orderedEquals([...remaining]..sort((a, b) => b.compareTo(a))));
  });

  test('a route with no line matches nothing', () {
    const empty = DrivingRouteModel(points: [], distanceMeters: 0, durationSeconds: 0);

    expect(RouteMatcher(empty).match(35, 36), isNull);
  });
}
