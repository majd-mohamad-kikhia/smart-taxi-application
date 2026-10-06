import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
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

typedef _Call = ({double carLat, double carLng, double targetLat, double targetLng, bool keepLine});

/// Always answers with the same road and "3 km / 10 min left".
class _FakeRouteTracker extends Fake implements TripRouteTracker {
  static const line = [RoutePointModel(1, 1), RoutePointModel(2, 2)];

  final List<_Call> calls = [];
  int resets = 0;

  @override
  void reset() => resets++;

  @override
  Future<TripRouteSnapshot> update({
    required double carLat,
    required double carLng,
    required double targetLat,
    required double targetLng,
    bool keepLine = false,
  }) async {
    calls.add((
      carLat: carLat,
      carLng: carLng,
      targetLat: targetLat,
      targetLng: targetLng,
      keepLine: keepLine,
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
    expect(tracker.calls.last, (carLat: 5.0, carLng: 6.0, targetLat: 10.0, targetLng: 20.0, keepLine: false));
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

  test('in progress: a fixed line and the time to the dropoff, starting at the pickup', () async {
    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    await pumpEventQueue();

    expect(cubit.state.routeLeg, RideRouteLeg.toDropoff);
    expect(tracker.calls.last, (carLat: 10.0, carLng: 20.0, targetLat: 30.0, targetLng: 40.0, keepLine: true));
    expect(cubit.state.eta, eta);

    socket.onDriverLocation(_tick(11, 21));
    await pumpEventQueue();
    expect(tracker.calls.last.carLat, 11.0);
    expect(cubit.state.drivenPath, hasLength(1));
  });

  test('completed: the time goes, the trip line stays under the payment dialog', () async {
    socket.onRideAccepted(_accepted());
    socket.onRideStatus(_status(4, 'in_progress'));
    await pumpEventQueue();

    socket.onRideStatus({..._status(5, 'completed'), 'final_price': 5000});
    await pumpEventQueue();

    expect(cubit.state.eta, isNull);
    expect(cubit.state.routePoints, _FakeRouteTracker.line);
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
