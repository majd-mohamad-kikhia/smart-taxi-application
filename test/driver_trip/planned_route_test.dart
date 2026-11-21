import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/planned_route_model.dart';
import 'package:mshoar/driver_features/driver_home/data/models/order_accept_result_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/driver_trip_location_service.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/open_trip_registry.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_repository.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/driver_trip_route_repository.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart';

const _line = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
const _otherLine = '_ibE_seK_seK_seK';

Map<String, dynamic> _planned([String polyline = _line]) => {
  'polyline': polyline,
  'distance_km': 4.65,
  'duration_min': 9,
  'provider': 'osm',
};

Map<String, dynamic> _offer([Map<String, dynamic> extra = const {}]) => {
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
  ...extra,
};

class _FakeRepository extends Fake implements DriverTripRepository {}

class _FakeLocation extends Fake implements DriverTripLocationService {
  @override
  Stream<Position> positionStream() => const Stream.empty();

  @override
  Future<Position?> currentPosition() async => null;

  @override
  Future<Position?> lastKnownPosition() async => null;
}

class _FakeRouteRepository extends Fake implements DriverTripRouteRepository {}

DriverTripCubit _cubit(
  OrderOfferModel order, {
  Stream<Map<String, dynamic>> updates = const Stream.empty(),
}) => DriverTripCubit(
  _FakeRepository(),
  _FakeLocation(),
  _FakeRouteRepository(),
  OpenTripRegistry(),
  const Stream.empty(),
  const Stream.empty(),
  updates,
  order,
);

void main() {
  group('where the road comes from', () {
    test('the accept ack carries it, inside ride like the eta does', () {
      final result = OrderAcceptResult.fromAck({
        'ok': true,
        'ride': {'planned_route': _planned()},
      });
      expect(result.plannedRoute!.points, hasLength(3));
      expect(OrderAcceptResult.fromAck({'ok': true}).plannedRoute, isNull);
    });

    test('the active ride carries it', () {
      final ride = DriverActiveRideModel.tryParse({
        'id': 30,
        'status': 'accepted',
        'pickup_lat': 33.5,
        'pickup_lng': 36.2,
        'dropoff_lat': 33.4,
        'dropoff_lng': 36.5,
        'planned_route': _planned(),
      })!;
      expect(ride.order.plannedRoute!.points, hasLength(3));
    });
  });

  group('DriverTripCubit draws it and asks for nothing', () {
    test('the server road, as it came', () async {
      final order = OrderOfferModel.fromJson(_offer()).withPlannedRoute(
        PlannedRouteModel.tryParse(_planned()),
      );
      final cubit = _cubit(order);
      expect(cubit.state.routePoints, order.plannedRoute!.points);
      await cubit.close();
    });

    test('no road yet: a straight line from the pickup to the drop-off', () async {
      final cubit = _cubit(OrderOfferModel.fromJson(_offer()));
      expect(cubit.state.routePoints, hasLength(2));
      expect(cubit.state.routePoints.first.lat, 33.5138);
      expect(cubit.state.routePoints.last.lng, 36.5156);
      await cubit.close();
    });

    test('an office edit with a new road replaces the line', () async {
      final updates = StreamController<Map<String, dynamic>>();
      final order = OrderOfferModel.fromJson(_offer()).withPlannedRoute(
        PlannedRouteModel.tryParse(_planned()),
      );
      final cubit = _cubit(order, updates: updates.stream);
      final before = cubit.state.routePoints;

      updates.add({
        'details_updated': true,
        'ride': {
          'id': 30,
          'status': 'accepted',
          'pickup_lat': 33.5138,
          'pickup_lng': 36.2765,
          'dropoff_lat': 33.4114,
          'dropoff_lng': 36.5156,
          'planned_route': _planned(_otherLine),
        },
      });
      await pumpEventQueue();

      expect(cubit.state.routePoints, isNot(before));
      expect(
        cubit.state.routePoints,
        PlannedRouteModel.tryParse(_planned(_otherLine))!.points,
      );
      await cubit.close();
      await updates.close();
    });

    test('an update without a road keeps the one drawn', () async {
      final updates = StreamController<Map<String, dynamic>>();
      final order = OrderOfferModel.fromJson(_offer()).withPlannedRoute(
        PlannedRouteModel.tryParse(_planned()),
      );
      final cubit = _cubit(order, updates: updates.stream);
      final before = cubit.state.routePoints;

      updates.add({
        'details_updated': true,
        'ride': {
          'id': 30,
          'status': 'accepted',
          'pickup_lat': 33.5138,
          'pickup_lng': 36.2765,
          'dropoff_lat': 33.4114,
          'dropoff_lng': 36.5156,
          'note': 'two bags',
        },
      });
      await pumpEventQueue();

      expect(cubit.state.order.note, 'two bags');
      expect(cubit.state.routePoints, before);
      await cubit.close();
      await updates.close();
    });
  });
}
