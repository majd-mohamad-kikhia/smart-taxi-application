import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/data/repositories/ride_request_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/home_cubit.dart';

class _FakeAccountBlock extends Fake implements AccountBlockCubit {}

class _FakeRideRepository extends Fake implements RideRequestRepository {}

class _FakeLocation extends CurrentLocationService {
  Object? failure;
  Position? known = _position;

  @override
  Future<Position> getCurrentLocation() async {
    final error = failure;
    if (error != null) throw error;
    return _position;
  }

  @override
  Future<Position?> getPositionIfAllowed() async => known;

  @override
  Future<Position?> getPositionAskingOnce() async => known;
}

class _FakePlaces extends Fake implements PlacesRepository {
  String? address = 'شارع الأمير سلطان';

  @override
  Future<String?> addressFor(
    double latitude,
    double longitude, {
    String reason = 'unspecified',
  }) async => address;
}

final _position = Position(
  latitude: 35.52,
  longitude: 35.79,
  timestamp: DateTime(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

const _home = PickedLocationModel(latitude: 1, longitude: 1, address: 'home');
const _work = PickedLocationModel(latitude: 2, longitude: 2, address: 'work');

void main() {
  late _FakeLocation location;
  late _FakePlaces places;
  late HomeCubit cubit;

  setUp(() {
    location = _FakeLocation();
    places = _FakePlaces();
    cubit = HomeCubit(
      SessionCubit(),
      _FakeRideRepository(),
      _FakeAccountBlock(),
      location,
      places,
    );
  });

  tearDown(() => cubit.close());

  group('resetPoints', () {
    test('clears both points and the quote', () {
      cubit
        ..setFromLocation(_home)
        ..setToLocation(_work)
        ..resetPoints();

      expect(cubit.state.fromLocation, isNull);
      expect(cubit.state.toLocation, isNull);
      expect(cubit.state.quote, isNull);
    });

    test('clears a lone point too', () {
      cubit
        ..setToLocation(_work)
        ..resetPoints();
      expect(cubit.state.toLocation, isNull);
    });

    test('does nothing when no point is set', () {
      final states = <Object>[];
      final sub = cubit.stream.listen(states.add);
      cubit.resetPoints();
      expect(states, isEmpty);
      sub.cancel();
    });
  });

  group('locateMe', () {
    test('moves the map and sets the pickup to the found address', () async {
      await cubit.locateMe();

      final state = cubit.state;
      expect(state.isLocating, isFalse);
      expect(state.locateCount, 1);
      expect(state.userLocation?.latitude, 35.52);
      expect(state.fromLocation?.address, 'شارع الأمير سلطان');
      expect(state.errorMessage, isNull);
    });

    test('moves the map again for the same spot', () async {
      await cubit.locateMe();
      await cubit.locateMe();

      expect(cubit.state.locateCount, 2);
    });

    test('leaves the pickup unset when no address is found', () async {
      places.address = null;

      await cubit.locateMe();

      expect(cubit.state.fromLocation, isNull);
      expect(cubit.state.locateCount, 1);
      expect(cubit.state.errorMessage, AppStrings.current.locationUnresolved);
    });

    test('reports a denied permission and does not move the map', () async {
      location.failure = const LocationPermissionDeniedException(
        LocationFailureReason.permissionDenied,
      );

      await cubit.locateMe();

      expect(cubit.state.isLocating, isFalse);
      expect(cubit.state.locateCount, 0);
      expect(cubit.state.errorMessage, AppStrings.current.errLocationDenied);
    });

    testWidgets('a GPS message clears itself after a few seconds', (
      tester,
    ) async {
      location.failure = const LocationPermissionDeniedException(
        LocationFailureReason.serviceDisabled,
      );

      await cubit.locateMe();
      expect(
        cubit.state.errorMessage,
        AppStrings.current.errLocationServiceOff,
      );

      await tester.pump(const Duration(seconds: 3));
      expect(
        cubit.state.errorMessage,
        AppStrings.current.errLocationServiceOff,
      );

      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.errorMessage, isNull);
    });

    testWidgets('asking again shows the message afresh, for a full 4 seconds', (
      tester,
    ) async {
      location.failure = const LocationPermissionDeniedException(
        LocationFailureReason.serviceDisabled,
      );
      await cubit.locateMe();
      await tester.pump(const Duration(seconds: 2));

      await cubit.locateMe();
      await tester.pump(const Duration(seconds: 3));
      expect(
        cubit.state.errorMessage,
        AppStrings.current.errLocationServiceOff,
      );

      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.errorMessage, isNull);
    });
  });

  group('setDefaultPickup', () {
    test(
      'moves the map and makes the customer\'s position the pickup',
      () async {
        await cubit.setDefaultPickup();

        expect(cubit.state.locateCount, 1);
        expect(cubit.state.fromLocation?.latitude, 35.52);
        expect(cubit.state.fromLocation?.address, 'شارع الأمير سلطان');
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test('keeps a pickup the customer already has', () async {
      cubit.setFromLocation(_home);

      await cubit.setDefaultPickup();

      expect(cubit.state.fromLocation, _home);
      expect(cubit.state.locateCount, 0);
    });

    test(
      'does not overwrite a pickup chosen while the address loads',
      () async {
        final pending = cubit.setDefaultPickup();
        cubit.setFromLocation(_home);
        await pending;

        expect(cubit.state.fromLocation, _home);
      },
    );

    test('stays quiet when the position is unknown', () async {
      location.known = null;

      await cubit.setDefaultPickup();

      expect(cubit.state.locateCount, 0);
      expect(cubit.state.fromLocation, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('moves the map but stays quiet when no address is found', () async {
      places.address = null;

      await cubit.setDefaultPickup();

      expect(cubit.state.locateCount, 1);
      expect(cubit.state.fromLocation, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test(
      'puts the customer back as the pickup after the points are cleared',
      () async {
        cubit
          ..setFromLocation(_home)
          ..setToLocation(_work)
          ..resetPoints();
        expect(cubit.state.fromLocation, isNull);
        expect(cubit.state.toLocation, isNull);

        await pumpEventQueue();

        expect(cubit.state.fromLocation?.latitude, 35.52);
        expect(cubit.state.toLocation, isNull);
      },
    );

    test(
      'puts the customer back as the pickup after a ride has ended',
      () async {
        cubit
          ..setFromLocation(_home)
          ..setToLocation(_work)
          ..resetAfterRideEnded();

        await pumpEventQueue();

        expect(cubit.state.fromLocation?.latitude, 35.52);
        expect(cubit.state.toLocation, isNull);
      },
    );
  });
}
