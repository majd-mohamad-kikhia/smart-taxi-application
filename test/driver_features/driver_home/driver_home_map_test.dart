import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/driving_route_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/services/google_routes_service.dart';
import 'package:mshoar/core/services/route_exception.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/driver_socket_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/new_order_alert.dart';
import 'package:mshoar/driver_features/driver_home/data/location_ticker.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_home_map_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_state.dart';

class _FakeSocket extends Fake implements DriverSocketService {
  void Function(Map<String, dynamic>)? offer;
  void Function(Map<String, dynamic>)? remove;

  @override
  void setOrderListeners({
    required void Function(Map<String, dynamic> data) onOrdersSnapshot,
    required void Function(Map<String, dynamic> data) onOrderOffer,
    required void Function(Map<String, dynamic> data) onOrderRemove,
  }) {
    offer = onOrderOffer;
    remove = onOrderRemove;
  }
}

class _FakePresence extends Fake implements DriverPresenceCubit {
  @override
  Stream<DriverPresenceState> get stream => const Stream.empty();
}

class _SilentAlert implements NewOrderAlert {
  @override
  Future<void> start({OrderOfferModel? order}) async {}

  @override
  Future<void> stop() async {}
}

class _FakeLocation extends Fake implements CurrentLocationService {
  Position? known;

  @override
  Future<Position?> getPositionIfAllowed() async => known;
}

class _FakeTicker extends Fake implements LocationTicker {
  final controller = StreamController<Position>.broadcast();
  Position? last;

  @override
  Stream<Position> get positions => controller.stream;

  @override
  Position? get lastPosition => last;
}

/// Answers each ride from a [Completer], so a test decides when and how.
class _FakeRoutes extends Fake implements GoogleRoutesService {
  final Map<double, Completer<DrivingRouteModel>> pending = {};
  final List<double> asked = [];

  @override
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    asked.add(fromLat);
    return (pending[fromLat] = Completer<DrivingRouteModel>()).future;
  }
}

DrivingRouteModel _road(double marker) => DrivingRouteModel(
  points: [RoutePointModel(marker, 36), RoutePointModel(marker + 0.1, 36.1)],
  distanceMeters: 1000,
  durationSeconds: 120,
);

Position _fix(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

/// An offer whose pickup latitude is [rideId] + 0.5, to tell roads apart.
Map<String, dynamic> _offer(int rideId) => {
  'ride_id': rideId,
  'vehicle_type_id': 2,
  'pickup_lat': rideId + 0.5,
  'pickup_lng': 36.3,
  'dropoff_lat': 33.4,
  'dropoff_lng': 36.5,
  'distance_km': 1.4,
  'estimated_duration_min': 4,
  'estimated_price': 284,
  'requested_at': '2026-10-03T09:12:44Z',
  'distance_to_pickup_km': 0.8,
};

void main() {
  late _FakeSocket socket;
  late DriverOrdersCubit orders;

  setUp(() {
    socket = _FakeSocket();
    orders = DriverOrdersCubit(
      socket,
      _FakeLocation(),
      _FakePresence(),
      _SilentAlert(),
    );
  });

  tearDown(() => orders.close());

  group('the offer in view', () {
    test(
      'a new offer is the one in view, the earlier one stays on the list',
      () {
        socket.offer!(_offer(1));
        expect(orders.state.selectedOrder?.rideId, 1);

        socket.offer!(_offer(2));

        expect(orders.state.selectedOrder?.rideId, 2);
        expect(orders.state.orders.map((o) => o.rideId), [1, 2]);
        expect(orders.state.selectedIndex, 1);
      },
    );

    test('an update to an offer already shown does not steal the view', () {
      socket.offer!(_offer(1));
      socket.offer!(_offer(2));
      orders.selectOrder(1);

      socket.offer!(_offer(2));

      expect(orders.state.selectedOrder?.rideId, 1);
    });

    test('selecting another offer switches, an unknown one is ignored', () {
      socket.offer!(_offer(1));
      socket.offer!(_offer(2));

      orders.selectOrder(1);
      expect(orders.state.selectedOrder?.rideId, 1);

      orders.selectOrder(99);
      expect(orders.state.selectedOrder?.rideId, 1);
    });

    test('when the offer in view goes away the first one is shown', () {
      socket.offer!(_offer(1));
      socket.offer!(_offer(2));

      socket.remove!({'ride_id': 2});

      expect(orders.state.selectedOrder?.rideId, 1);
    });

    test('no offers means nothing in view', () {
      expect(orders.state.selectedOrder, isNull);
      expect(orders.state.selectedIndex, 0);
    });
  });

  group('DriverHomeMapCubit', () {
    late _FakeTicker ticker;
    late _FakeLocation location;
    late _FakeRoutes routes;
    late DriverHomeMapCubit cubit;

    DriverHomeMapCubit build() =>
        DriverHomeMapCubit(ticker, location, orders, routes);

    setUp(() {
      ticker = _FakeTicker();
      location = _FakeLocation();
      routes = _FakeRoutes();
    });

    tearDown(() async {
      await cubit.close();
      await ticker.controller.close();
    });

    test('follows the live fixes', () async {
      cubit = build();
      expect(cubit.state.hasDriverPosition, isFalse);

      ticker.controller.add(_fix(33.5, 36.3));
      await pumpEventQueue();

      expect(cubit.state.driverLat, 33.5);
      expect(cubit.state.driverLng, 36.3);
    });

    test('starts from the fix the ticker already has', () {
      ticker.last = _fix(33.1, 36.1);
      cubit = build();
      expect(cubit.state.driverLat, 33.1);
    });

    test(
      'offline, the phone\'s last known position puts the driver on the map',
      () async {
        location.known = _fix(33.2, 36.2);
        cubit = build();
        await pumpEventQueue();
        expect(cubit.state.driverLat, 33.2);
      },
    );

    test('a live fix is not overwritten by the late last known one', () async {
      location.known = _fix(33.2, 36.2);
      ticker.last = _fix(33.9, 36.9);
      cubit = build();
      await pumpEventQueue();
      expect(cubit.state.driverLat, 33.9);
    });

    test(
      'draws the road of the offer in view, from pickup to drop-off',
      () async {
        cubit = build();
        socket.offer!(_offer(1));
        await pumpEventQueue();

        expect(cubit.state.routeRideId, 1);
        expect(cubit.state.orderRoute, isEmpty);
        expect(routes.asked, [1.5]);

        routes.pending[1.5]!.complete(_road(1.5));
        await pumpEventQueue();

        expect(cubit.state.orderRoute, _road(1.5).points);
      },
    );

    test('flipping between offers asks for each road only once', () async {
      cubit = build();
      socket.offer!(_offer(1));
      await pumpEventQueue();
      routes.pending[1.5]!.complete(_road(1.5));
      socket.offer!(_offer(2));
      await pumpEventQueue();
      routes.pending[2.5]!.complete(_road(2.5));
      await pumpEventQueue();

      orders.selectOrder(1);
      await pumpEventQueue();

      expect(cubit.state.routeRideId, 1);
      expect(cubit.state.orderRoute, _road(1.5).points);
      expect(routes.asked, [1.5, 2.5]);
    });

    test('a slow road for an offer left behind is dropped', () async {
      cubit = build();
      socket.offer!(_offer(1));
      await pumpEventQueue();
      socket.offer!(_offer(2));
      await pumpEventQueue();

      routes.pending[2.5]!.complete(_road(2.5));
      await pumpEventQueue();
      routes.pending[1.5]!.complete(_road(1.5));
      await pumpEventQueue();

      expect(cubit.state.routeRideId, 2);
      expect(cubit.state.orderRoute, _road(2.5).points);
    });

    test(
      'a road that cannot be found leaves the line straight, quietly',
      () async {
        cubit = build();
        socket.offer!(_offer(1));
        await pumpEventQueue();

        routes.pending[1.5]!.completeError(RouteException('no route'));
        await pumpEventQueue();

        expect(cubit.state.routeRideId, 1);
        expect(cubit.state.orderRoute, isEmpty);
      },
    );

    test('no offer left clears the road', () async {
      cubit = build();
      socket.offer!(_offer(1));
      await pumpEventQueue();
      routes.pending[1.5]!.complete(_road(1.5));
      await pumpEventQueue();

      socket.remove!({'ride_id': 1});
      await pumpEventQueue();

      expect(cubit.state.routeRideId, isNull);
      expect(cubit.state.orderRoute, isEmpty);
    });
  });
}
