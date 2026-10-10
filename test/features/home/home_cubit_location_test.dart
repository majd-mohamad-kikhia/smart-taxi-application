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
}

class _FakePlaces extends Fake implements PlacesRepository {
  String? address = 'شارع الأمير سلطان';

  @override
  Future<String?> addressFor(double latitude, double longitude) async => address;
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

  group('swapLocations', () {
    test('exchanges pickup and dropoff', () {
      cubit
        ..setFromLocation(_home)
        ..setToLocation(_work)
        ..swapLocations();

      expect(cubit.state.fromLocation, _work);
      expect(cubit.state.toLocation, _home);
    });

    test('moves a lone point to the other side', () {
      cubit
        ..setFromLocation(_home)
        ..swapLocations();

      expect(cubit.state.fromLocation, isNull);
      expect(cubit.state.toLocation, _home);
    });

    test('does nothing while no point is picked', () {
      final before = cubit.state;
      cubit.swapLocations();

      expect(cubit.state, before);
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

    testWidgets('a GPS message clears itself after a few seconds', (tester) async {
      location.failure = const LocationPermissionDeniedException(
        LocationFailureReason.serviceDisabled,
      );

      await cubit.locateMe();
      expect(cubit.state.errorMessage, AppStrings.current.errLocationServiceOff);

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.errorMessage, AppStrings.current.errLocationServiceOff);

      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.errorMessage, isNull);
    });

    testWidgets('asking again shows the message afresh, for a full 4 seconds', (tester) async {
      location.failure = const LocationPermissionDeniedException(
        LocationFailureReason.serviceDisabled,
      );
      await cubit.locateMe();
      await tester.pump(const Duration(seconds: 2));

      await cubit.locateMe();
      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.errorMessage, AppStrings.current.errLocationServiceOff);

      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.errorMessage, isNull);
    });
  });

  group('centerOnUser', () {
    test('moves the map without touching the pickup', () async {
      await cubit.centerOnUser();

      expect(cubit.state.locateCount, 1);
      expect(cubit.state.fromLocation, isNull);
    });

    test('stays quiet when the position is unknown', () async {
      location.known = null;

      await cubit.centerOnUser();

      expect(cubit.state.locateCount, 0);
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
