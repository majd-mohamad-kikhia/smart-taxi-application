import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/driver_socket_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/new_order_alert.dart';
import 'package:mshoar/driver_features/driver_home/data/models/order_accept_result_model.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_orders_state.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_state.dart';

const _walletText = 'يرجى شحن محفظتك أولاً';

class _FakeSocket extends Fake implements DriverSocketService {
  Object? answer;
  double? sentLat;
  double? sentLng;
  void Function(Map<String, dynamic>)? onOffer;

  @override
  void setOrderListeners({
    required void Function(Map<String, dynamic> data) onOrdersSnapshot,
    required void Function(Map<String, dynamic> data) onOrderOffer,
    required void Function(Map<String, dynamic> data) onOrderRemove,
  }) {
    onOffer = onOrderOffer;
  }

  @override
  void acceptOrder({
    required int rideId,
    double? lat,
    double? lng,
    required void Function(OrderAcceptResult result) onResult,
  }) {
    sentLat = lat;
    sentLng = lng;
    onResult(OrderAcceptResult.fromAck(answer));
  }
}

class _FakeLocation extends Fake implements CurrentLocationService {
  Position? position;

  @override
  Future<Position?> quickPosition({Duration limit = const Duration(seconds: 2)}) async => position;
}

class _SilentAlert implements NewOrderAlert {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _FakePresence extends Fake implements DriverPresenceCubit {
  @override
  Stream<DriverPresenceState> get stream => const Stream.empty();
}

Map<String, dynamic> _offer(int rideId) => {
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
    };

const _walletRefusal = {
  'success': false,
  'message': _walletText,
  'errors': {'wallet_balance': _walletText},
};

void main() {
  group('OrderAcceptResult.fromAck', () {
    test('success', () {
      expect(OrderAcceptResult.fromAck({'ok': true}).ok, isTrue);
      expect(OrderAcceptResult.fromAck({'success': true}).ok, isTrue);
    });

    test('a plain refusal keeps the server text', () {
      final result = OrderAcceptResult.fromAck({'ok': false, 'error': 'Ride already taken'});

      expect(result.ok, isFalse);
      expect(result.message, 'Ride already taken');
      expect(result.walletTooLow, isFalse);
    });

    test('the API error shape: wallet too low, recognised by errors.wallet_balance', () {
      final result = OrderAcceptResult.fromAck(_walletRefusal);

      expect(result.ok, isFalse);
      expect(result.walletTooLow, isTrue);
      expect(result.message, _walletText);
    });

    test('the same error carried inside `error`', () {
      final result = OrderAcceptResult.fromAck({
        'ok': false,
        'error': {
          'message': _walletText,
          'errors': {'wallet_balance': _walletText},
        },
      });

      expect(result.walletTooLow, isTrue);
      expect(result.message, _walletText);
    });

    test('the wallet text is the message when nothing else carries one', () {
      final result = OrderAcceptResult.fromAck({
        'ok': false,
        'errors': {'wallet_balance': _walletText},
      });

      expect(result.walletTooLow, isTrue);
      expect(result.message, _walletText);
    });

    test('the same words without errors.wallet_balance are not a wallet refusal', () {
      final result = OrderAcceptResult.fromAck({'ok': false, 'error': _walletText});

      expect(result.walletTooLow, isFalse);
      expect(result.message, _walletText);
    });

    test('an unexpected shape is a failure, never an exception', () {
      for (final ack in [null, 'nope', 42, <Object?>[], {'ok': false, 'error': 7}, {'errors': 'x'}]) {
        final result = OrderAcceptResult.fromAck(ack);
        expect(result.ok, isFalse, reason: '$ack');
        expect(result.walletTooLow, isFalse, reason: '$ack');
      }
    });
  });

  group('DriverOrdersCubit.acceptOrder', () {
    late _FakeSocket socket;
    late _FakeLocation location;
    late DriverOrdersCubit cubit;

    setUp(() {
      socket = _FakeSocket();
      location = _FakeLocation();
      cubit = DriverOrdersCubit(socket, location, _FakePresence(), _SilentAlert());
      socket.onOffer!(_offer(24));
    });

    tearDown(() => cubit.close());

    test('a low wallet is refused: the server text, the card stays, nothing is accepted', () async {
      socket.answer = _walletRefusal;

      final accepted = (await cubit.acceptOrder(24)).ok;

      expect(accepted, isFalse);
      expect(cubit.state.errorMessage, _walletText);
      expect(cubit.state.errorIsWalletTooLow, isTrue);
      expect(cubit.state.acceptingRideId, isNull);
      expect(cubit.state.orders.map((o) => o.rideId), [24]);
    });

    test('the driver can try again, and is told again', () async {
      socket.answer = _walletRefusal;
      final shown = <DriverOrdersState>[];
      final sub = cubit.stream.listen(shown.add);

      await cubit.acceptOrder(24);
      await cubit.acceptOrder(24);
      await pumpEventQueue();
      await sub.cancel();

      // Each attempt clears the last message first, so a listener that fires
      // on "message changed" fires for the second refusal too.
      expect(shown.where((s) => s.errorIsWalletTooLow), hasLength(2));
      expect(shown.where((s) => s.errorMessage == null && s.acceptingRideId != null), hasLength(2));
    });

    test('any other refusal is an ordinary error', () async {
      socket.answer = {'ok': false, 'error': 'Ride already taken'};

      await cubit.acceptOrder(24);

      expect(cubit.state.errorMessage, 'Ride already taken');
      expect(cubit.state.errorIsWalletTooLow, isFalse);
    });

    test('a refusal that says nothing falls back to the generic message', () async {
      socket.answer = {'ok': false};

      await cubit.acceptOrder(24);

      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.errorIsWalletTooLow, isFalse);
    });

    test('success clears any earlier error', () async {
      socket.answer = {'ok': false, 'error': 'x'};
      await cubit.acceptOrder(24);

      socket.answer = {'ok': true};
      final accepted = (await cubit.acceptOrder(24)).ok;

      expect(accepted, isTrue);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.errorIsWalletTooLow, isFalse);
    });

    test('the driver\'s position goes with the accept, and the time to pickup comes back', () async {
      location.position = Position(
        latitude: 33.51,
        longitude: 36.27,
        timestamp: DateTime(2026, 10, 7),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      socket.answer = {
        'ok': true,
        'ride': {
          'eta': {'duration_seconds': 1163, 'duration_minutes': 20, 'distance_meters': 4016},
        },
      };

      final result = await cubit.acceptOrder(24);

      expect(socket.sentLat, 33.51);
      expect(socket.sentLng, 36.27);
      expect(result.eta?.durationMinutes, 20);
      expect(result.eta?.distanceMeters, 4016);
    });

    test('without a position it still accepts, with no time to pickup', () async {
      socket.answer = {'ok': true, 'ride': {'eta': null}};

      final result = await cubit.acceptOrder(24);

      expect(result.ok, isTrue);
      expect(socket.sentLat, isNull);
      expect(socket.sentLng, isNull);
      expect(result.eta, isNull);
    });
  });
}
