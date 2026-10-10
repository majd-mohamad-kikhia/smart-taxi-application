import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/driver_socket_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/new_order_alert.dart';
import 'package:mshoar/driver_features/driver_home/data/models/order_accept_result_model.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_state.dart';

class _FakeSocket extends Fake implements DriverSocketService {
  late void Function(Map<String, dynamic>) onSnapshot;
  late void Function(Map<String, dynamic>) onOffer;
  late void Function(Map<String, dynamic>) onRemove;
  Object? answer = {'ok': true};

  @override
  void setOrderListeners({
    required void Function(Map<String, dynamic> data) onOrdersSnapshot,
    required void Function(Map<String, dynamic> data) onOrderOffer,
    required void Function(Map<String, dynamic> data) onOrderRemove,
  }) {
    onSnapshot = onOrdersSnapshot;
    onOffer = onOrderOffer;
    onRemove = onOrderRemove;
  }

  @override
  void acceptOrder({
    required int rideId,
    double? lat,
    double? lng,
    required void Function(OrderAcceptResult result) onResult,
  }) => onResult(OrderAcceptResult.fromAck(answer));
}

class _FakeLocation extends Fake implements CurrentLocationService {
  @override
  Future<Position?> quickPosition({
    Duration limit = const Duration(seconds: 2),
  }) async => null;
}

class _FakePresence extends Fake implements DriverPresenceCubit {
  @override
  Stream<DriverPresenceState> get stream => const Stream.empty();
}

class _CountingAlert implements NewOrderAlert {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;
}

Map<String, dynamic> _offer(int rideId, {DateTime? expiresAt}) => {
  'ride_id': rideId,
  'vehicle_type_id': 2,
  'pickup_lat': 33.5,
  'pickup_lng': 36.3,
  'dropoff_lat': 33.4,
  'dropoff_lng': 36.5,
  'distance_km': 1.4,
  'estimated_duration_min': 4,
  'estimated_price': 284,
  'requested_at': '2026-10-03T09:12:44Z',
  'distance_to_pickup_km': 0.8,
  if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
};

void main() {
  late _FakeSocket socket;
  late _CountingAlert alert;
  late DriverOrdersCubit cubit;

  setUp(() {
    socket = _FakeSocket();
    alert = _CountingAlert();
    cubit = DriverOrdersCubit(socket, _FakeLocation(), _FakePresence(), alert);
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test('a new order sounds the alert', () {
    socket.onOffer(_offer(1));
    expect(alert.starts, 1);
  });

  test('an update of an order already listed does not ring again', () {
    socket.onOffer(_offer(1));
    socket.onOffer(_offer(1));
    expect(alert.starts, 1);
  });

  test('a second, different order rings again', () {
    socket.onOffer(_offer(1));
    socket.onOffer(_offer(2));
    expect(alert.starts, 2);
  });

  test('the list loaded on connect does not ring', () {
    socket.onSnapshot({
      'orders': [_offer(1), _offer(2)],
    });
    expect(alert.starts, 0);
  });

  test('the alert stops once the last order is gone, not before', () {
    socket.onOffer(_offer(1));
    socket.onOffer(_offer(2));
    socket.onRemove({'ride_id': 1});
    expect(alert.stops, 0);
    socket.onRemove({'ride_id': 2});
    expect(alert.stops, 1);
  });

  test('tapping accept stops the alert', () async {
    socket.onOffer(_offer(1));
    await cubit.acceptOrder(1);
    expect(alert.stops, 1);
  });

  test('going offline (reset) stops the alert', () {
    socket.onOffer(_offer(1));
    cubit.reset();
    expect(alert.stops, 1);
  });

  group('offers in waves', () {
    DateTime inSeconds(int n) =>
        DateTime.now().toUtc().add(Duration(seconds: n));

    test('the same ride offered again in a later wave rings again', () {
      socket.onOffer(_offer(1, expiresAt: inSeconds(10)));
      socket.onOffer(_offer(1, expiresAt: inSeconds(30)));
      expect(alert.starts, 2);
      expect(cubit.state.orders, hasLength(1));
    });

    test('a repeat of the same offer (same turn) does not ring again', () {
      final turn = inSeconds(10);
      socket.onOffer(_offer(1, expiresAt: turn));
      socket.onOffer(_offer(1, expiresAt: turn));
      expect(alert.starts, 1);
    });

    test(
      'a timed-out card is removed, and the ride comes back as a new card',
      () {
        socket.onOffer(_offer(1, expiresAt: inSeconds(10)));
        socket.onRemove({'ride_id': 1, 'reason': 'timeout'});
        expect(cubit.state.orders, isEmpty);
        expect(alert.stops, 1);
        socket.onOffer(_offer(1, expiresAt: inSeconds(40)));
        expect(alert.starts, 2);
        expect(cubit.state.orders, hasLength(1));
      },
    );

    test('a late accept (409 expired) closes the card with no error', () async {
      socket.onOffer(_offer(1, expiresAt: inSeconds(10)));
      socket.answer = {
        'ok': false,
        'status': 409,
        'error': 'This offer has expired',
      };

      final result = await cubit.acceptOrder(1);

      expect(result.ok, isFalse);
      expect(result.offerExpired, isTrue);
      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.acceptingRideId, isNull);
    });

    test(
      'a refusal in another language is still read as expired once the countdown ran out',
      () async {
        socket.onOffer(_offer(1, expiresAt: inSeconds(-1)));
        socket.answer = {'ok': false, 'error': 'انتهت صلاحية هذا العرض'};

        await cubit.acceptOrder(1);

        expect(cubit.state.orders, isEmpty);
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test('other refusals keep the card and show their error', () async {
      socket.onOffer(_offer(1, expiresAt: inSeconds(10)));
      socket.answer = {'ok': false, 'error': 'Something else'};

      await cubit.acceptOrder(1);

      expect(cubit.state.orders, hasLength(1));
      expect(cubit.state.errorMessage, 'Something else');
    });
  });
}
