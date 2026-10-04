import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/planned_route_loader.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/driver_trip_location_service.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/open_trip_registry.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_ride_start_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_repository.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_route_repository.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_state.dart';

Map<String, dynamic> _offer({Object? passengers = _absent}) => {
  'ride_id': 30,
  'vehicle_type_id': 2,
  'pickup_lat': 33.5138,
  'pickup_lng': 36.2765,
  'dropoff_lat': 33.4114,
  'dropoff_lng': 36.5156,
  'distance_km': 24.9,
  'estimated_duration_min': 30,
  'estimated_price': 16204.5,
  'requested_at': '2026-10-03T10:00:00Z',
  'distance_to_pickup_km': 1.2,
  if (passengers != _absent) 'passengers_count': passengers,
};

const _absent = Object();

class _FakeRepository extends Fake implements DriverTripRepository {
  DriverRideStartModel reply = const DriverRideStartModel();
  DriverTripException? error;
  final List<int?> sentCounts = [];

  @override
  Future<DriverRideStartModel> startRide(int rideId, {int? passengersCount}) async {
    sentCounts.add(passengersCount);
    final failure = error;
    if (failure != null) throw failure;
    return reply;
  }
}

class _FakeLocation extends Fake implements DriverTripLocationService {
  @override
  Stream<Position> positionStream() => const Stream.empty();

  @override
  Future<Position?> currentPosition() async => null;

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

class _FakeRouteRepository extends Fake implements DriverTripRouteRepository {}

DriverTripCubit _cubit(_FakeRepository repository, OrderOfferModel order) {
  return DriverTripCubit(
    repository,
    _FakeLocation(),
    _FakeRouteLoader(),
    _FakeRouteRepository(),
    OpenTripRegistry(),
    const Stream.empty(),
    const Stream.empty(),
    const Stream.empty(),
    order,
  );
}

void main() {
  group('passengers_count parsing', () {
    test('order offer reads the number, or null when missing or empty', () {
      expect(OrderOfferModel.fromJson(_offer(passengers: 3)).passengersCount, 3);
      expect(OrderOfferModel.fromJson(_offer(passengers: null)).passengersCount, isNull);
      expect(OrderOfferModel.fromJson(_offer()).passengersCount, isNull);
      expect(OrderOfferModel.fromJson(_offer(passengers: 0)).passengersCount, isNull);
    });

    test('an office edit changes or clears it; other edits keep it', () {
      final order = OrderOfferModel.fromJson(_offer(passengers: 3));
      expect(order.withUpdatedDetails({'note': 'x'}).passengersCount, 3);
      expect(order.withUpdatedDetails({'passengers_count': 2}).passengersCount, 2);
      expect(order.withUpdatedDetails({'passengers_count': null}).passengersCount, isNull);
    });

    test('active ride and start reply read it', () {
      final ride = DriverActiveRideModel.tryParse({
        'id': 30,
        'status': 'arrived',
        'pickup_lat': 33.5,
        'pickup_lng': 36.2,
        'dropoff_lat': 33.4,
        'dropoff_lng': 36.5,
        'passengers_count': 4,
      })!;
      expect(ride.order.passengersCount, 4);
      expect(
        DriverRideStartModel.fromRideJson({'id': 30, 'status_id': 4, 'passengers_count': 3})
            .passengersCount,
        3,
      );
    });
  });

  group('DriverTripCubit.startRide', () {
    test('customer app order sends the picked number and keeps the saved one', () async {
      final repository = _FakeRepository()
        ..reply = const DriverRideStartModel(passengersCount: 3);
      final cubit = _cubit(repository, OrderOfferModel.fromJson(_offer()));
      expect(cubit.state.needsPassengersCount, isTrue);

      await cubit.startRide(passengersCount: 3);

      expect(repository.sentCounts, [3]);
      expect(cubit.state.status, DriverTripStatus.inProgress);
      expect(cubit.state.order.passengersCount, 3);
      await cubit.close();
    });

    test('office order never sends a number and keeps the reception\'s', () async {
      final repository = _FakeRepository()
        ..reply = const DriverRideStartModel(passengersCount: 3);
      final cubit = _cubit(repository, OrderOfferModel.fromJson(_offer(passengers: 3)));
      expect(cubit.state.needsPassengersCount, isFalse);

      await cubit.startRide(passengersCount: 5);

      expect(repository.sentCounts, [null]);
      expect(cubit.state.order.passengersCount, 3);
      await cubit.close();
    });

    test('too many for the car type: shows the error and stays at pickup', () async {
      final repository = _FakeRepository()
        ..error = const DriverTripException('too many', statusCode: 422);
      final cubit = _cubit(repository, OrderOfferModel.fromJson(_offer()));

      await cubit.startRide(passengersCount: 6);

      expect(cubit.state.status, DriverTripStatus.accepted);
      expect(cubit.state.errorMessage, 'too many');
      expect(cubit.state.isUpdating, isFalse);
      expect(cubit.state.order.passengersCount, isNull);
      await cubit.close();
    });
  });
}
