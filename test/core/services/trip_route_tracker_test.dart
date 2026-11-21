import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/driving_route_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/google_routes_service.dart';
import 'package:mshoar/core/services/route_exception.dart';
import 'package:mshoar/core/services/trip_route_tracker.dart';

/// North from ([fromLat], [fromLng]) for 0.03° (~3.3 km); the service
/// "computes" 3000 m / 600 s for it.
DrivingRouteModel _roadFrom(double fromLat, [double fromLng = 36]) => DrivingRouteModel(
      points: [
        for (var i = 0; i <= 3; i++) RoutePointModel(fromLat + i * 0.01, fromLng),
      ],
      distanceMeters: 3000,
      durationSeconds: 600,
    );

class _FakeService extends Fake implements GoogleRoutesService {
  int calls = 0;
  bool fail = false;
  Completer<DrivingRouteModel>? gate;

  @override
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    bool trafficAware = true,
    Duration? reuseFor,
  }) async {
    calls++;
    if (fail) throw const RouteException('down');
    final gate = this.gate;
    if (gate != null) return gate.future;
    return _roadFrom(fromLat, fromLng);
  }
}

void main() {
  late _FakeService service;
  late DateTime now;
  late TripRouteTracker tracker;

  Future<TripRouteSnapshot> update(double lat, {double lng = 36}) {
    return tracker.update(carLat: lat, carLng: lng, targetLat: 35.03, targetLng: 36);
  }

  setUp(() {
    service = _FakeService();
    now = DateTime(2026, 10, 6, 12);
    tracker = TripRouteTracker(service, now: () => now);
  });

  test('fetches once, then follows the car on the route without asking again', () async {
    final first = await update(35.00);
    expect(first.line, hasLength(4));
    expect(first.progress!.remainingMeters, closeTo(3000, 1));

    final second = await update(35.015);
    final third = await update(35.025);

    expect(service.calls, 1);
    expect(second.progress!.remainingMeters, closeTo(1500, 1));
    expect(third.progress!.remainingMeters, lessThan(second.progress!.remainingMeters));
    expect(identical(third.line, first.line), isTrue);
  });

  test('a car that leaves the route never gets a new one', () async {
    final first = await update(35.00);

    now = now.add(const Duration(minutes: 1));
    final off = await update(35.015, lng: 36.02);

    expect(service.calls, 1);
    expect(off.progress, isNull);
    expect(identical(off.line, first.line), isTrue);
  });

  test('an old route is not refreshed for traffic either', () async {
    await update(35.00);
    now = now.add(const Duration(hours: 1));
    await update(35.01);
    expect(service.calls, 1);
  });

  test('a known road is used as it is and never fetched', () async {
    tracker.useRoute(_roadFrom(35.00));
    final snapshot = await update(35.015);

    expect(service.calls, 0);
    expect(snapshot.line, hasLength(4));
    expect(snapshot.progress!.remainingMeters, closeTo(1500, 1));
  });

  test('a failed request is retried after 30 s, then 60 s, then given up', () async {
    service.fail = true;
    final failed = await update(35.00);
    expect(failed.line, isEmpty);
    expect(failed.progress, isNull);

    now = now.add(const Duration(seconds: 10));
    await update(35.00);
    expect(service.calls, 1);

    now = now.add(const Duration(seconds: 21));
    await update(35.00); // 30 s after the first
    expect(service.calls, 2);

    now = now.add(const Duration(seconds: 31));
    await update(35.00);
    expect(service.calls, 2);

    now = now.add(const Duration(seconds: 30));
    await update(35.00); // 60 s after the second
    expect(service.calls, 3);

    // Three attempts are all a leg gets.
    now = now.add(const Duration(hours: 1));
    await update(35.00);
    expect(service.calls, 3);
  });

  test('a failure followed by an answer keeps that answer for good', () async {
    service.fail = true;
    await update(35.00);
    service.fail = false;
    now = now.add(const Duration(seconds: 31));
    final retried = await update(35.00);
    expect(retried.line, isNotEmpty);

    now = now.add(const Duration(hours: 1));
    await update(35.01);
    expect(service.calls, 2);
  });

  test('one request at a time, and a reset drops the one in flight', () async {
    service.gate = Completer<DrivingRouteModel>();
    final pending = update(35.00);
    await update(35.001);
    expect(service.calls, 1);

    tracker.reset();
    service.gate!.complete(_roadFrom(35.00));
    final dropped = await pending;

    expect(dropped.line, isEmpty);
    expect(dropped.progress, isNull);
  });

  test('a reset starts the next leg afresh', () async {
    await update(35.00);
    tracker.reset();
    await update(35.00);
    expect(service.calls, 2);
  });
}
