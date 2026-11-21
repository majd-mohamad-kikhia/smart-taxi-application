import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/models/driving_route_model.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/models/planned_route_model.dart';
import 'package:mshoar/core/models/ride_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/models/trip_eta_model.dart';
import 'package:mshoar/core/network/api_client.dart';
import 'package:mshoar/core/services/trip_route_tracker.dart';
import 'package:mshoar/core/utils/route_matcher.dart';
import 'package:mshoar/features/tracking/data/datasources/customer_ride_socket_service.dart';
import 'package:mshoar/features/tracking/presentation/cubit/ride_tracking_cubit.dart';
import 'package:mshoar/features/tracking/presentation/cubit/ride_tracking_state.dart';

class _FakeSocket extends Fake implements CustomerRideSocketService {
  late void Function(Map<String, dynamic> data) onRideAccepted;
  late void Function(Map<String, dynamic> data) onDriverLocation;
  late void Function(Map<String, dynamic> data) onRideStatus;

  @override
  void connect({
    required String accessToken,
    required void Function() onConnect,
    required void Function() onDisconnect,
    required void Function(dynamic error) onConnectError,
    required void Function(Map<String, dynamic> data) onRideAccepted,
    required void Function(Map<String, dynamic> data) onDriverLocation,
    required void Function(Map<String, dynamic> data) onRideStatus,
    required void Function(Map<String, dynamic> data) onRidePauseUpdate,
    required void Function(Map<String, dynamic>? data) onActiveRide,
    required void Function(Map<String, dynamic> data) onRidePaid,
  }) {
    this.onRideAccepted = onRideAccepted;
    this.onDriverLocation = onDriverLocation;
    this.onRideStatus = onRideStatus;
  }

  @override
  void disconnect() {}
}

class _FakeAccountBlock extends Fake implements AccountBlockCubit {}

typedef _Call = ({double carLat, double carLng, double targetLat, double targetLng});

/// Always answers with the same road and "3 km / 10 min left".
class _FakeRouteTracker extends Fake implements TripRouteTracker {
  static const line = [RoutePointModel(1, 1), RoutePointModel(2, 2)];

  final List<_Call> calls = [];
  final List<DrivingRouteModel> usedRoutes = [];
  int resets = 0;

  @override
  void reset() => resets++;

  @override
  void useRoute(DrivingRouteModel route) => usedRoutes.add(route);

  @override
  Future<TripRouteSnapshot> update({
    required double carLat,
    required double carLng,
    required double targetLat,
    required double targetLng,
  }) async {
    calls.add((
      carLat: carLat,
      carLng: carLng,
      targetLat: targetLat,
      targetLng: targetLng,
    ));
    return const TripRouteSnapshot(
      line: line,
      progress: RouteProgress(remainingMeters: 3012, remainingSeconds: 598),
    );
  }
}

const _ride = RideModel(
  id: 122,
  vehicleTypeId: 2,
  priceIsEstimate: true,
  statusId: 2,
  status: 'accepted',
);

const _pickup = PickedLocationModel(latitude: 10, longitude: 20);
const _dropoff = PickedLocationModel(latitude: 30, longitude: 40);

Map<String, dynamic> _accepted() => {
      'ride': {'id': 122, 'vehicle_type_id': 2, 'status_id': 2, 'status': 'accepted'},
      'driver': {'id': 7, 'first_name': 'Ali', 'last_name': 'Omar'},
      'vehicle': {'id': 9},
    };

Map<String, dynamic> _tick(double lat, double lng) => {
      'ride_id': 122,
      'lat': lat,
      'lng': lng,
      'updated_at': '2026-10-06T12:00:00Z',
    };

Map<String, dynamic> _status(int id, String status) =>
    {'ride_id': 122, 'status_id': id, 'status': status};

void main() {
  late _FakeSocket socket;
  late _FakeRouteTracker tracker;
  late RideTrackingCubit cubit;

  const eta = TripEtaModel(distanceMeters: 3000, minutes: 10);

  setUp(() {
    ApiClient.authToken = 'token';
    socket = _FakeSocket();
    tracker = _FakeRouteTracker();
    cubit = RideTrackingCubit(
      socket,
      tracker,
      _FakeAccountBlock(),
      initialRide: _ride,
      pickup: _pickup,
      dropoff: _dropoff,
    )..connect();
  });

  tearDown(() async {
    await cubit.close();
    ApiClient.authToken = null;
  });

  test('before a driver has a position there is nothing to route', () async {
    socket.onRideAccepted(_accepted());
    await pumpEventQueue();

    expect(tracker.calls, isEmpty);
    expect(cubit.state.eta, isNull);
    expect(cubit.state.routePoints, isEmpty);
  });

  test('the driver heading to the pickup: road line and rounded time to the pickup', () async {
    socket.onRideAccepted(_accepted());
    socket.onDriverLocation(_tick(5, 6));
    await pumpEventQueue();

    expect(cubit.state.routeLeg, RideRouteLeg.toPickup);
    expect(tracker.calls.last, (carLat: 5.0, carLng: 6.0, targetLat: 10.0, targetLng: 20.0));
    expect(cubit.state.routePoints, _FakeRouteTracker.line);
    expect(cubit.state.eta, eta);
  });

  test('arrived: the way to the pickup and its time are gone', () async {
    socket.onRideAccepted(_accepted());
    socket.onDriverLocation(_tick(5, 6));
    await pumpEventQueue();

    socket.onRideStatus(_status(3, 'arrived'));
    await pumpEventQueue();

    expect(cubit.state.routeLeg, RideRouteLeg.none);
    expect(cubit.state.routePoints, isEmpty);
    expect(cubit.state.eta, isNull);
    expect(tracker.resets, greaterThanOrEqualTo(2));
  });

  const straight = [RoutePointModel(10, 20), RoutePointModel(30, 40)];

  test('in progress without a planned route: a straight line, and no routing request', () async {
    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    socket.onDriverLocation(_tick(11, 21));
    await pumpEventQueue();

    expect(cubit.state.routeLeg, RideRouteLeg.toDropoff);
    expect(tracker.calls, isEmpty);
    expect(tracker.usedRoutes, isEmpty);
    expect(cubit.state.routePoints, straight);
    expect(cubit.state.eta, isNull);
    expect(cubit.state.drivenPath, hasLength(1));
  });

  test('in progress with a planned route: it is drawn as it came, the time is matched locally', () async {
    await cubit.close();
    tracker = _FakeRouteTracker();
    socket = _FakeSocket();
    final planned = PlannedRouteModel.tryParse({
      'polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'distance_km': 4.65,
      'duration_min': 9,
    })!;
    cubit = RideTrackingCubit(
      socket,
      tracker,
      _FakeAccountBlock(),
      initialRide: RideModel(
        id: 122,
        vehicleTypeId: 2,
        priceIsEstimate: true,
        statusId: 2,
        status: 'accepted',
        plannedRoute: planned,
      ),
      pickup: _pickup,
      dropoff: _dropoff,
    )..connect();

    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    socket.onDriverLocation(_tick(11, 21));
    await pumpEventQueue();

    expect(cubit.state.routePoints, planned.points);
    expect(tracker.usedRoutes, hasLength(1));
    expect(tracker.usedRoutes.single.distanceMeters, 4650);
    // Matched onto the known road: no request, only the local progress.
    expect(cubit.state.eta, eta);
  });

  test('a ride whose road was not ready asks once, a moment later', () async {
    await cubit.close();
    final planned = PlannedRouteModel.tryParse({
      'polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    })!;
    var asked = 0;
    cubit = RideTrackingCubit(
      _FakeSocket(),
      _FakeRouteTracker(),
      _FakeAccountBlock(),
      initialRide: _ride,
      pickup: _pickup,
      dropoff: _dropoff,
      fetchPlannedRoute: (id) async {
        asked++;
        expect(id, 122);
        return planned;
      },
      plannedRouteRetryDelay: const Duration(milliseconds: 10),
    );
    expect(cubit.state.plannedRoute, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(asked, 1);
    expect(cubit.state.plannedRoute, planned.points);
  });

  test('a ride that already has its road is not fetched again', () async {
    await cubit.close();
    var asked = 0;
    cubit = RideTrackingCubit(
      _FakeSocket(),
      _FakeRouteTracker(),
      _FakeAccountBlock(),
      initialRide: _ride,
      pickup: _pickup,
      dropoff: _dropoff,
      plannedRoute: const [RoutePointModel(1, 1), RoutePointModel(2, 2)],
      fetchPlannedRoute: (id) async {
        asked++;
        return null;
      },
      plannedRouteRetryDelay: const Duration(milliseconds: 10),
    );

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(asked, 0);
  });

  test('completed: the time goes, the trip line stays under the payment dialog', () async {
    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    await pumpEventQueue();

    socket.onRideStatus({..._status(5, 'completed'), 'final_price': 5000});
    await pumpEventQueue();

    expect(cubit.state.eta, isNull);
    expect(cubit.state.routePoints, straight);
  });

  test('a tick that changes nothing visible does not emit again', () async {
    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    await pumpEventQueue();

    final emitted = <RideTrackingState>[];
    final sub = cubit.stream.listen(emitted.add);
    socket.onDriverLocation(_tick(11, 21));
    await pumpEventQueue();
    await sub.cancel();

    // The tick itself (new position + driven path); the route/ETA part of it
    // is identical to what is already shown.
    expect(emitted, hasLength(1));
  });
}
