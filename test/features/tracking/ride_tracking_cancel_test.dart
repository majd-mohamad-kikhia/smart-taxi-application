import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/models/cancel_penalty_model.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/models/ride_model.dart';
import 'package:mshoar/core/network/api_client.dart';
import 'package:mshoar/core/services/planned_route_loader.dart';
import 'package:mshoar/features/tracking/data/datasources/customer_ride_socket_service.dart';
import 'package:mshoar/features/tracking/presentation/cubit/ride_tracking_cubit.dart';
import 'package:mshoar/features/tracking/presentation/cubit/ride_tracking_state.dart';

class _FakeSocket extends Fake implements CustomerRideSocketService {
  void Function(Map<String, dynamic> data)? onRideStatus;
  void Function(bool ok, String? error, Map<String, dynamic>? ride)? pendingCancel;

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
    this.onRideStatus = onRideStatus;
  }

  @override
  void cancelRide({
    required int rideId,
    String? cancellationReason,
    required void Function(bool ok, String? error, Map<String, dynamic>? ride) onResult,
  }) {
    pendingCancel = onResult;
  }

  @override
  void disconnect() {}
}

class _FakeAccountBlock extends Fake implements AccountBlockCubit {
  final List<CancelPenaltyModel> penalties = [];
  int refreshes = 0;

  @override
  void applyCancelPenalty(CancelPenaltyModel penalty) => penalties.add(penalty);

  @override
  Future<void> refresh({bool notifyIfBlocked = false}) async => refreshes++;
}

class _FakeRouteLoader extends Fake implements PlannedRouteLoader {}

const _ride = RideModel(
  id: 122,
  vehicleTypeId: 2,
  priceIsEstimate: true,
  statusId: 2,
  status: 'accepted',
);

const _penaltyRide = {
  'id': 122,
  'status': 'cancelled',
  'cancel_penalty': {
    'counted': true,
    'cancel_strikes': 1,
    'strike_limit': 3,
    'remaining': 2,
    'blocked': false,
    'block_hours': 24,
    'message': 'warning',
  },
};

void main() {
  late _FakeSocket socket;
  late _FakeAccountBlock accountBlock;
  late RideTrackingCubit cubit;

  setUp(() {
    ApiClient.authToken = 'token';
    socket = _FakeSocket();
    accountBlock = _FakeAccountBlock();
    cubit = RideTrackingCubit(
      socket,
      _FakeRouteLoader(),
      accountBlock,
      initialRide: _ride,
      pickup: const PickedLocationModel(latitude: 1, longitude: 1),
      dropoff: const PickedLocationModel(latitude: 2, longitude: 2),
    )..connect();
  });

  tearDown(() async {
    await cubit.close();
    ApiClient.authToken = null;
  });

  test('own cancel waits for its answer and hands over the penalty', () {
    cubit.submitCancellation('plans changed');
    socket.onRideStatus!({'ride_id': 122, 'status_id': 6, 'status': 'cancelled'});
    expect(cubit.state.exitReason, isNull);

    socket.pendingCancel!(true, null, Map<String, dynamic>.from(_penaltyRide));

    expect(cubit.state.exitReason, RideTrackingExitReason.cancelledByUser);
    expect(accountBlock.penalties.single.message, 'warning');
  });

  test('a cancel before any driver accepted hands over nothing', () {
    cubit.submitCancellation('plans changed');
    socket.pendingCancel!(true, null, {'id': 122, 'status': 'cancelled', 'cancel_penalty': null});
    expect(cubit.state.exitReason, RideTrackingExitReason.cancelledByUser);
    expect(accountBlock.penalties, isEmpty);
  });

  testWidgets('no answer after the ride shows cancelled: closes and reloads the block', (tester) async {
    cubit.submitCancellation('plans changed');
    socket.onRideStatus!({'ride_id': 122, 'status_id': 6, 'status': 'cancelled'});
    await tester.pump(const Duration(seconds: 5));
    expect(cubit.state.exitReason, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(cubit.state.exitReason, RideTrackingExitReason.cancelledByUser);
    expect(accountBlock.refreshes, 1);
  });

  test('a cancel by someone else still closes at once', () {
    socket.onRideStatus!({'ride_id': 122, 'status_id': 6, 'status': 'cancelled'});
    expect(cubit.state.exitReason, RideTrackingExitReason.cancelledByServer);
  });
}
