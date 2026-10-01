import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/driver_features/driver_route/data/datasources/route_location_service.dart';
import 'package:mshoar/driver_features/driver_route/data/datasources/route_session_local_data_source.dart';
import 'package:mshoar/driver_features/driver_route/data/models/route_session_model.dart';
import 'package:mshoar/driver_features/driver_route/data/repositories/route_session_repository.dart';
import 'package:mshoar/driver_features/driver_route/presentation/cubit/route_tracker_cubit.dart';

class _MemoryStore extends RouteSessionLocalDataSource {
  RouteSessionModel? saved;
  int clears = 0;

  @override
  Future<RouteSessionModel?> load() async => saved;

  @override
  Future<void> save(RouteSessionModel session) async => saved = session;

  @override
  Future<void> clear() async {
    saved = null;
    clears++;
  }
}

class _FakeLocation extends RouteLocationService {
  bool permission = true;
  Position? current;
  final fixes = StreamController<Position>.broadcast();

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<Position?> lastKnownPosition() async => null;

  @override
  Future<Position?> currentPosition() async => current;

  @override
  Stream<Position> positionStream() => fixes.stream;
}

Position _fix(double lat, double lng, {double accuracy = 5}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 1, 1),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// The shared one-shot GPS read the locate button uses.
class _FakeCurrentLocation extends CurrentLocationService {
  Position? position;
  LocationFailureReason? failure;

  @override
  Future<Position> getCurrentLocation() async {
    final reason = failure;
    if (reason != null) throw LocationPermissionDeniedException(reason);
    return position!;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _MemoryStore store;
  late _FakeLocation location;
  late _FakeCurrentLocation oneShot;
  late RouteTrackerCubit cubit;

  setUp(() {
    store = _MemoryStore();
    location = _FakeLocation();
    oneShot = _FakeCurrentLocation();
    cubit = RouteTrackerCubit(RouteSessionRepository(store), location, oneShot);
  });

  tearDown(() async {
    await cubit.close();
    await location.fixes.close();
  });

  test(
    'arrived then start moves through waiting to in progress and saves',
    () async {
      await cubit.load();
      await cubit.markArrived();
      expect(cubit.state.phase, RoutePhase.waiting);
      expect(cubit.state.session.arrivedAt, isNotNull);

      await cubit.startTrip();
      expect(cubit.state.phase, RoutePhase.inProgress);
      expect(cubit.state.session.startedAt, isNotNull);
      expect(store.saved?.phase, RoutePhase.inProgress);
    },
  );

  test('the trip can start without tapping arrived', () async {
    await cubit.load();
    await cubit.startTrip();
    expect(cubit.state.phase, RoutePhase.inProgress);
    expect(cubit.state.session.arrivedAt, isNull);
  });

  test(
    'without location access the trip does not start and an error is shown',
    () async {
      location.permission = false;
      await cubit.load();
      await cubit.startTrip();
      expect(cubit.state.phase, RoutePhase.idle);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isStarting, isFalse);
    },
  );

  test(
    'fixes draw the path and add up the distance; jitter and bad fixes are ignored',
    () async {
      await cubit.load();
      await cubit.startTrip();

      location.fixes.add(_fix(32.0000, 13.0));
      await _settle();
      location.fixes.add(_fix(32.0010, 13.0)); // about 111 m on
      await _settle();
      location.fixes.add(_fix(32.00105, 13.0)); // about 5 m: jitter
      await _settle();
      location.fixes.add(_fix(32.0020, 13.0, accuracy: 500)); // too inaccurate
      await _settle();

      final session = cubit.state.session;
      expect(session.points, hasLength(2));
      expect(session.distanceMeters, closeTo(111, 3));
      expect(cubit.state.carLat, 32.0020); // the pin still follows every fix
    },
  );

  test(
    'stops are recorded and finishing while stopped closes the stop',
    () async {
      await cubit.load();
      await cubit.startTrip();

      await cubit.pauseTrip();
      expect(cubit.state.session.isPaused, isTrue);
      await cubit.resumeTrip();
      expect(cubit.state.session.isPaused, isFalse);
      expect(cubit.state.session.pauseCount, 1);

      await cubit.pauseTrip();
      await cubit.finishTrip();
      final session = cubit.state.session;
      expect(session.phase, RoutePhase.finished);
      expect(session.finishedAt, isNotNull);
      expect(session.pauseCount, 2);
      expect(session.isPaused, isFalse);
      expect(session.pauses.every((p) => p.endedAt != null), isTrue);
    },
  );

  test('pause is ignored when not in progress or already stopped', () async {
    await cubit.load();
    await cubit.pauseTrip();
    expect(cubit.state.session.pauseCount, 0);

    await cubit.startTrip();
    await cubit.pauseTrip();
    await cubit.pauseTrip();
    expect(cubit.state.session.pauseCount, 1);
  });

  test('a finished route stays saved until a new one is started', () async {
    await cubit.load();
    await cubit.startTrip();
    await cubit.finishTrip();
    expect(store.saved?.phase, RoutePhase.finished);

    // A fresh cubit (app reopened) still shows the finished route.
    final reopened = RouteTrackerCubit(RouteSessionRepository(store), location, oneShot);
    await reopened.load();
    expect(reopened.state.phase, RoutePhase.finished);
    await reopened.close();

    await cubit.startNewRoute();
    expect(cubit.state.phase, RoutePhase.idle);
    expect(cubit.state.session.points, isEmpty);
    expect(store.saved, isNull);
    expect(store.clears, 1);
  });

  group('locate button', () {
    test(
      'moves the pin to the current position and asks the map to centre',
      () async {
        await cubit.load();
        oneShot.position = _fix(32.5, 13.5);
        await cubit.locateMe();
        expect(cubit.state.carLat, 32.5);
        expect(cubit.state.carLng, 13.5);
        expect(cubit.state.locateRequest, 1);
        expect(cubit.state.isLocating, isFalse);

        // Locating again re-centres even though the position is unchanged.
        await cubit.locateMe();
        expect(cubit.state.locateRequest, 2);
      },
    );

    test(
      'works on a finished route without touching the recorded route',
      () async {
        await cubit.load();
        await cubit.startTrip();
        location.fixes.add(_fix(32.0, 13.0));
        await _settle();
        location.fixes.add(_fix(32.001, 13.0));
        await _settle();
        await cubit.finishTrip();
        final before = cubit.state.session;

        oneShot.position = _fix(40, 20);
        await cubit.locateMe();
        expect(cubit.state.carLat, 40);
        expect(cubit.state.session, before);
      },
    );

    test('shows an error when location access is refused', () async {
      await cubit.load();
      oneShot.failure = LocationFailureReason.permissionDenied;
      await cubit.locateMe();
      expect(cubit.state.errorMessage, AppStrings.current.errLocationDenied);
      expect(cubit.state.locateRequest, 0);
      expect(cubit.state.isLocating, isFalse);
    });

    test('shows a different error when the location service is off', () async {
      await cubit.load();
      oneShot.failure = LocationFailureReason.serviceDisabled;
      await cubit.locateMe();
      expect(cubit.state.errorMessage, AppStrings.current.errLocationServiceOff);
    });
  });

  test('a new route can only be started after finishing', () async {
    await cubit.load();
    await cubit.startTrip();
    await cubit.startNewRoute();
    expect(cubit.state.phase, RoutePhase.inProgress);
    expect(store.clears, 0);
  });

  test(
    'a trip still running when the app closed resumes and joins the gap',
    () async {
      store.saved = RouteSessionModel(
        phase: RoutePhase.inProgress,
        startedAt: DateTime(2026, 1, 1, 12),
        distanceMeters: 500,
        points: const [RoutePointModel(32.0000, 13.0)],
      );
      await cubit.load();
      expect(cubit.state.phase, RoutePhase.inProgress);
      await _settle();

      location.fixes.add(
        _fix(32.0010, 13.0),
      ); // about 111 m from the saved point
      await _settle();
      expect(cubit.state.session.points, hasLength(2));
      expect(cubit.state.session.distanceMeters, closeTo(611, 3));
    },
  );

  group('RouteSessionModel', () {
    test('survives a JSON round trip', () {
      final session = RouteSessionModel(
        phase: RoutePhase.finished,
        arrivedAt: DateTime(2026, 1, 1, 11, 50),
        startedAt: DateTime(2026, 1, 1, 12),
        finishedAt: DateTime(2026, 1, 1, 12, 30),
        pauses: [
          RoutePauseRecordModel(
            startedAt: DateTime(2026, 1, 1, 12, 10),
            endedAt: DateTime(2026, 1, 1, 12, 15),
          ),
        ],
        distanceMeters: 1234.5,
        points: const [
          RoutePointModel(32.0, 13.0),
          RoutePointModel(32.1, 13.1),
        ],
      );
      expect(RouteSessionModel.fromJson(session.toJson()), session);
    });

    test('durations: waiting, trip, stops and driving time', () {
      final session = RouteSessionModel(
        phase: RoutePhase.finished,
        arrivedAt: DateTime(2026, 1, 1, 11, 55),
        startedAt: DateTime(2026, 1, 1, 12),
        finishedAt: DateTime(2026, 1, 1, 12, 30),
        pauses: [
          RoutePauseRecordModel(
            startedAt: DateTime(2026, 1, 1, 12, 10),
            endedAt: DateTime(2026, 1, 1, 12, 15),
          ),
        ],
      );
      final now = DateTime(2026, 1, 1, 13);
      expect(session.waitingDuration(now), const Duration(minutes: 5));
      expect(session.tripDuration(now), const Duration(minutes: 30));
      expect(session.pausedDuration(now), const Duration(minutes: 5));
      expect(session.drivingDuration(now), const Duration(minutes: 25));
    });
  });
}
