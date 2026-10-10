import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/planned_route_loader.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/driver_trip_location_service.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/driver_trip_remote_data_source.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/open_trip_registry.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_ride_finish_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_repository.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_route_repository.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_state.dart';

Map<String, dynamic> _rideJson({double distanceKm = 1.2}) => {
  'ride_id': 36,
  'vehicle_type_id': 2,
  'pickup_lat': 35.5,
  'pickup_lng': 35.8,
  'dropoff_lat': 35.6,
  'dropoff_lng': 35.9,
  'distance_km': distanceKm,
  'estimated_duration_min': 5,
  'estimated_price': 190,
  'requested_at': '2026-10-03T10:00:00Z',
  'distance_to_pickup_km': 1.0,
};

final _finished = DriverRideFinishModel.fromRideJson({
  'id': 36,
  'status': 'completed',
  'price': 190,
  'estimated_price': 190,
  'distance_km': 1.2,
});

/// Answers `finishRide` from a script: each entry is a result or an error.
class _FakeRepository extends Fake implements DriverTripRepository {
  final script = <Object>[];
  final sentDistances = <double>[];
  DriverRideFinishModel? finishedOnServer;
  int recoveryChecks = 0;

  @override
  Future<DriverRideFinishModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) async {
    sentDistances.add(distanceKm);
    final next = script.removeAt(0);
    if (next is DriverRideFinishModel) return next;
    throw next;
  }

  @override
  Future<DriverRideFinishModel?> fetchFinishedActiveRide() async {
    recoveryChecks++;
    return finishedOnServer;
  }
}

class _FakeLocation extends Fake implements DriverTripLocationService {
  Object? fixError;

  @override
  Stream<Position> positionStream() => const Stream.empty();

  @override
  Future<Position?> currentPosition() async {
    final error = fixError;
    if (error != null) throw error;
    return null;
  }

  @override
  Future<Position?> lastKnownPosition() async => null;
}

class _FakeRouteLoader extends Fake implements PlannedRouteLoader {
  @override
  Future<List<RoutePointModel>> load({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async => const [];
}

class _FakeRouteRepository extends Fake implements DriverTripRouteRepository {
  @override
  Future<void> finishAndUpload(int rideId, List points) async {}
}

DriverTripCubit _inProgressCubit(
  _FakeRepository repository,
  _FakeLocation location, {
  double distanceKm = 1.2,
}) {
  final ride = DriverActiveRideModel.tryParse({
    'id': 36,
    'status': 'in_progress',
    'pickup_lat': 35.5,
    'pickup_lng': 35.8,
    'dropoff_lat': 35.6,
    'dropoff_lng': 35.9,
    'distance_km': distanceKm,
  })!;
  return DriverTripCubit(
    repository,
    location,
    _FakeRouteLoader(),
    _FakeRouteRepository(),
    OpenTripRegistry(),
    const Stream.empty(),
    const Stream.empty(),
    const Stream.empty(),
    OrderOfferModel.fromJson(_rideJson(distanceKm: distanceKm)),
    resume: ride,
  );
}

const _offline = DriverTripException('No connection', isNetwork: true);
const _conflict = DriverTripException(
  'Ride cannot be finished',
  statusCode: 409,
);

void main() {
  late _FakeRepository repository;
  late _FakeLocation location;

  setUp(() {
    repository = _FakeRepository();
    location = _FakeLocation();
  });

  test('a finish that goes through completes the trip', () async {
    repository.script.add(_finished);
    final cubit = _inProgressCubit(repository, location);

    await cubit.finishRide();

    expect(cubit.state.status, DriverTripStatus.completed);
    expect(cubit.state.isUpdating, isFalse);
    expect(cubit.state.fare?.finalPrice, 190);
    await cubit.close();
  });

  test(
    'no connection: the spinner stops, the error shows and the finish is kept',
    () async {
      repository.script.add(_offline);
      final cubit = _inProgressCubit(repository, location);

      await cubit.finishRide();

      expect(cubit.state.status, DriverTripStatus.inProgress);
      expect(cubit.state.isUpdating, isFalse);
      expect(cubit.state.isFinishQueued, isTrue);
      expect(cubit.state.errorMessage, 'No connection');
      await cubit.close();
    },
  );

  test('Retry after a lost connection finishes the trip', () async {
    repository.script.addAll([_offline, _finished]);
    final cubit = _inProgressCubit(repository, location);

    await cubit.finishRide();
    await cubit.finishRide();

    expect(cubit.state.status, DriverTripStatus.completed);
    expect(cubit.state.isFinishQueued, isFalse);
    expect(repository.sentDistances, hasLength(2));
    await cubit.close();
  });

  testWidgets(
    'a queued finish is sent again by itself, with no new error each time',
    (tester) async {
      repository.script.addAll([_offline, _offline, _finished]);
      final cubit = _inProgressCubit(repository, location);
      // What the screen reacts to: the error changing to a new message.
      final shown = <String>[];
      String? last;
      cubit.stream.listen((s) {
        if (s.errorMessage != null && s.errorMessage != last) {
          shown.add(s.errorMessage!);
        }
        last = s.errorMessage;
      });

      cubit.finishRide();
      await tester.pump();
      expect(cubit.state.isFinishQueued, isTrue);

      await tester.pump(const Duration(seconds: 9));
      expect(repository.sentDistances, hasLength(2));
      expect(cubit.state.status, DriverTripStatus.inProgress);

      await tester.pump(const Duration(seconds: 9));
      expect(repository.sentDistances, hasLength(3));
      expect(cubit.state.status, DriverTripStatus.completed);
      expect(cubit.state.isFinishQueued, isFalse);
      // Only the driver's own tap showed an error.
      expect(shown, ['No connection']);
      await cubit.close();
    },
  );

  testWidgets('closing the screen stops the automatic retries', (tester) async {
    repository.script.add(_offline);
    final cubit = _inProgressCubit(repository, location);
    cubit.finishRide();
    await tester.pump();

    await cubit.close();
    await tester.pump(const Duration(minutes: 1));

    expect(repository.sentDistances, hasLength(1));
  });

  test(
    '409 after a lost answer: the trip is already completed on the server',
    () async {
      repository
        ..script.add(_conflict)
        ..finishedOnServer = _finished;
      final cubit = _inProgressCubit(repository, location);

      await cubit.finishRide();

      expect(repository.recoveryChecks, 1);
      expect(cubit.state.status, DriverTripStatus.completed);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    },
  );

  test(
    '409 and the server does not have it completed: shows the error',
    () async {
      repository.script.add(_conflict);
      final cubit = _inProgressCubit(repository, location);

      await cubit.finishRide();

      expect(cubit.state.status, DriverTripStatus.inProgress);
      expect(cubit.state.errorMessage, 'Ride cannot be finished');
      expect(cubit.state.isFinishQueued, isFalse);
      expect(cubit.state.isUpdating, isFalse);
      await cubit.close();
    },
  );

  testWidgets('a refusal (422) is shown at once and is not retried', (
    tester,
  ) async {
    repository.script.add(
      const DriverTripException('Invalid distance', statusCode: 422),
    );
    final cubit = _inProgressCubit(repository, location);

    cubit.finishRide();
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));

    expect(cubit.state.errorMessage, 'Invalid distance');
    expect(cubit.state.isFinishQueued, isFalse);
    expect(repository.sentDistances, hasLength(1));
    await cubit.close();
  });

  test('an unexpected failure still ends the spinner', () async {
    repository.script.add(StateError('unreadable answer'));
    final cubit = _inProgressCubit(repository, location);

    await cubit.finishRide();

    expect(cubit.state.isUpdating, isFalse);
    expect(cubit.state.errorMessage, AppStrings.current.errUnexpected);
    await cubit.close();
  });

  test('a GPS that fails does not hold the finish up', () async {
    location.fixError = PlatformException(code: 'PERMISSION_DENIED');
    repository.script.add(_finished);
    final cubit = _inProgressCubit(repository, location);

    await cubit.finishRide();

    expect(cubit.state.status, DriverTripStatus.completed);
    await cubit.close();
  });

  test('distance_km is always a number from 0 to 2000', () async {
    for (final quoted in [0.0, 12.345, 5000.0, double.nan, double.infinity]) {
      final repo = _FakeRepository()..script.add(_finished);
      final cubit = _inProgressCubit(repo, location, distanceKm: quoted);

      await cubit.finishRide();

      final sent = repo.sentDistances.single;
      expect(sent.isFinite, isTrue, reason: 'quoted $quoted');
      expect(sent, inInclusiveRange(0, 2000), reason: 'quoted $quoted');
      await cubit.close();
    }
  });

  group('DriverTripRepository.finishRide', () {
    test(
      'a finish that never answers fails after the timeout, as a network error',
      () async {
        final repo = DriverTripRepository(
          _HangingRemote(),
          finishTimeout: const Duration(milliseconds: 50),
        );

        await expectLater(
          repo.finishRide(rideId: 36, distanceKm: 1.2),
          throwsA(
            isA<DriverTripException>()
                .having((e) => e.isNetwork, 'isNetwork', isTrue)
                .having(
                  (e) => e.message,
                  'message',
                  AppStrings.current.errTimeout,
                ),
          ),
        );
      },
    );

    test(
      'an answer the app cannot read becomes a plain failure, not a crash',
      () async {
        final repo = DriverTripRepository(_BrokenRemote());

        await expectLater(
          repo.finishRide(rideId: 36, distanceKm: 1.2),
          throwsA(
            isA<DriverTripException>().having(
              (e) => e.isNetwork,
              'isNetwork',
              isFalse,
            ),
          ),
        );
      },
    );
  });
}

class _HangingRemote extends Fake implements DriverTripRemoteDataSource {
  @override
  Future<DriverRideFinishModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) => Completer<DriverRideFinishModel>().future;
}

class _BrokenRemote extends Fake implements DriverTripRemoteDataSource {
  @override
  Future<DriverRideFinishModel> finishRide({
    required int rideId,
    required double distanceKm,
  }) async => throw const FormatException('not a ride');
}
