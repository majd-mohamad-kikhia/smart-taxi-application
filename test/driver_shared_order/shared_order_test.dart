import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/deep_links/deep_link_service.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/driver_features/driver_shared_order/data/datasources/shared_order_remote_data_source.dart';
import 'package:mshoar/driver_features/driver_shared_order/data/models/shared_order_preview_model.dart';
import 'package:mshoar/driver_features/driver_shared_order/data/repositories/shared_order_repository.dart';
import 'package:mshoar/driver_features/driver_shared_order/presentation/cubit/shared_order_cubit.dart';
import 'package:mshoar/driver_features/driver_shared_order/presentation/cubit/shared_order_state.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/open_trip_registry.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';

const _token = 'Up7HtWZU2N1_J33rT4lm6A';

Map<String, dynamic> _previewJson({
  String availability = 'available',
  bool canAccept = true,
  String? opensAt,
  String pickupAddress = 'Square',
}) => {
  'availability': availability,
  'can_accept': canAccept,
  'message': 'hint',
  'opens_at': opensAt,
  'order': {
    'ride_id': 24,
    'vehicle_type_id': 2,
    'vehicle_type_name': 'comfort',
    'pickup_lat': 33.5138,
    'pickup_lng': 36.2765,
    'pickup_address': pickupAddress,
    'pickup_address_details': 'Next to the pharmacy',
    'dropoff_lat': 33.4114,
    'dropoff_lng': 36.5156,
    'dropoff_address': 'Airport',
    'dropoff_address_details': null,
    'stops': [
      {'stop_order': 2, 'lat': 33.4, 'lng': 36.4, 'address': 'Second'},
      {'stop_order': 1, 'lat': 33.5, 'lng': 36.3, 'address': 'First'},
    ],
    'note': 'two bags',
    'scheduled_at': null,
    'distance_km': 1.42,
    'estimated_duration_min': 4,
    'estimated_price': 284,
    'price_is_estimate': true,
    'order_source': 'call',
    'status_id': 1,
    'requested_at': '2026-10-03 09:12:44',
  },
};

SharedOrderPreviewModel _preview({String availability = 'available', bool canAccept = true}) =>
    SharedOrderPreviewModel.fromJson(
      _previewJson(availability: availability, canAccept: canAccept),
    );

DriverActiveRideModel _acceptedRide() => DriverActiveRideModel.tryParse({
  'id': 24,
  'status': 'accepted',
  'vehicle_type_id': 2,
  'pickup_lat': 33.5138,
  'pickup_lng': 36.2765,
  'dropoff_lat': 33.4114,
  'dropoff_lng': 36.5156,
  'requested_at': '2026-10-03 09:12:44',
})!;

class _FakeRepository implements SharedOrderRepository {
  final List<Future<SharedOrderPreviewModel> Function()> previews = [];
  Future<DriverActiveRideModel?> Function() onAccept = () async => _acceptedRide();
  int previewCalls = 0;
  int acceptCalls = 0;

  @override
  Future<SharedOrderPreviewModel> preview(String token) {
    previewCalls++;
    final next = previews.length > 1 ? previews.removeAt(0) : previews.single;
    return next();
  }

  @override
  Future<DriverActiveRideModel?> accept(String token) {
    acceptCalls++;
    return onAccept();
  }
}

void main() {
  _repositoryTests();

  group('DeepLinkService.tokenFrom', () {
    test('reads the https link and the app scheme fallback', () {
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/o/$_token')), _token);
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/o/$_token/')), _token);
      expect(DeepLinkService.tokenFrom(Uri.parse('smarttaxidriver://order/$_token')), _token);
    });

    test('ignores other hosts, paths and malformed tokens', () {
      expect(DeepLinkService.tokenFrom(Uri.parse('https://evil.co/o/$_token')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('http://smart-taxi.co/o/$_token')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/x/$_token')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/o/short')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/o/$_token/more')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('smarttaxidriver://ride/$_token')), isNull);
      expect(DeepLinkService.tokenFrom(Uri.parse('https://smart-taxi.co/o/Up7HtWZU2N1_J33rT4lm6!')), isNull);
    });
  });

  group('SharedOrderPreviewModel.fromJson', () {
    test('reads the order, its stops in order and the UTC opening time', () {
      final preview = SharedOrderPreviewModel.fromJson(
        _previewJson(availability: 'scheduled', canAccept: false, opensAt: '2026-10-03 10:00:00'),
      );
      expect(preview.availability, SharedOrderAvailability.scheduled);
      expect(preview.canAccept, isFalse);
      expect(preview.opensAt, DateTime.utc(2026, 10, 3, 10));
      expect(preview.rideId, 24);
      expect(preview.vehicleTypeName, 'comfort');
      expect(preview.stops, ['First', 'Second']);
      expect(preview.order.note, 'two bags');
      expect(preview.order.pickupAddressDetails, 'Next to the pharmacy');
      expect(preview.order.dropoffAddressDetails, isNull);
      expect(preview.order.estimatedPrice, 284);
    });

    test('an availability this version does not know is unknown', () {
      expect(SharedOrderAvailability.fromWire('something_new'), SharedOrderAvailability.unknown);
      expect(SharedOrderAvailability.fromWire('wrong_vehicle_type'), SharedOrderAvailability.wrongVehicleType);
    });
  });

  group('SharedOrderCubit', () {
    late _FakeRepository repository;
    late OpenTripRegistry openTrips;
    late StreamController<Map<String, dynamic>> closed;
    late StreamController<Map<String, dynamic>> updated;
    late StreamController<void> connected;
    late SharedOrderCubit cubit;

    setUp(() {
      repository = _FakeRepository()..previews.add(() async => _preview());
      openTrips = OpenTripRegistry();
      closed = StreamController.broadcast();
      updated = StreamController.broadcast();
      connected = StreamController.broadcast();
      cubit = SharedOrderCubit(
        repository,
        openTrips,
        token: _token,
        orderClosed: closed.stream,
        orderUpdated: updated.stream,
        socketConnected: connected.stream,
        isSocketConnected: () => true,
      );
    });

    tearDown(() async {
      await cubit.close();
      await closed.close();
      await updated.close();
      await connected.close();
    });

    test('shows the order with Accept when it is available', () async {
      await cubit.load();
      final state = cubit.state as SharedOrderLoaded;
      expect(state.preview.canAccept, isTrue);
      expect(state.accepting, isFalse);
    });

    test('a 404 is an invalid link', () async {
      repository.previews
        ..clear()
        ..add(() async => throw const SharedOrderException('nope', statusCode: 404));
      await cubit.load();
      expect(cubit.state, isA<SharedOrderInvalidLink>());
    });

    test('another driver taking it turns the screen to taken at once', () async {
      await cubit.load();
      closed.add({'ride_id': 24, 'reason': 'taken', 'taken_by_you': false});
      await pumpEventQueue();
      final state = cubit.state as SharedOrderClosed;
      expect(state.availability, SharedOrderAvailability.taken);
      expect(state.preview?.rideId, 24);
    });

    test('events about another order are ignored', () async {
      await cubit.load();
      closed.add({'ride_id': 99, 'reason': 'taken', 'taken_by_you': false});
      await pumpEventQueue();
      expect(cubit.state, isA<SharedOrderLoaded>());
    });

    test('the office cancelling it shows cancelled', () async {
      await cubit.load();
      closed.add({'ride_id': 24, 'reason': 'cancelled', 'taken_by_you': false});
      await pumpEventQueue();
      expect((cubit.state as SharedOrderClosed).availability, SharedOrderAvailability.cancelled);
    });

    test('accepting opens the trip and claims it', () async {
      await cubit.load();
      await cubit.accept();
      expect((cubit.state as SharedOrderAccepted).ride.order.rideId, 24);
      expect(openTrips.openRideId, 24);
    });

    test('losing the race shows taken', () async {
      repository.onAccept = () async => throw const SharedOrderException(
        'taken',
        statusCode: 409,
        availability: SharedOrderAvailability.taken,
      );
      await cubit.load();
      await cubit.accept();
      expect((cubit.state as SharedOrderClosed).availability, SharedOrderAvailability.taken);
    });

    test('a low wallet keeps the order and carries the server text, not an error', () async {
      repository.onAccept = () async => throw const SharedOrderException(
        'يرجى شحن محفظتك أولاً',
        statusCode: 403,
        walletTooLow: true,
      );
      await cubit.load();
      await cubit.accept();

      final state = cubit.state as SharedOrderLoaded;
      expect(state.walletMessage, 'يرجى شحن محفظتك أولاً');
      expect(state.acceptError, isNull);
      expect(state.accepting, isFalse);
      expect(state.preview.canAccept, isTrue);
    });

    test('after a top-up the same order can be accepted', () async {
      var calls = 0;
      repository.onAccept = () async {
        if (++calls == 1) {
          throw const SharedOrderException('low', statusCode: 403, walletTooLow: true);
        }
        return _acceptedRide();
      };
      await cubit.load();
      await cubit.accept();
      expect((cubit.state as SharedOrderLoaded).walletMessage, 'low');

      await cubit.accept();

      expect(cubit.state, isA<SharedOrderAccepted>());
    });

    test('a second refusal is reported again, not swallowed as "no change"', () async {
      repository.onAccept = () async =>
          throw const SharedOrderException('low', statusCode: 403, walletTooLow: true);
      await cubit.load();
      final shown = <SharedOrderState>[];
      final sub = cubit.stream.listen(shown.add);

      await cubit.accept();
      await cubit.accept();
      await pumpEventQueue();
      await sub.cancel();

      final messages = shown.whereType<SharedOrderLoaded>().map((s) => s.walletMessage);
      expect(messages.where((m) => m == 'low'), hasLength(2));
      expect(messages.where((m) => m == null), isNotEmpty);
    });

    test('opening the link with a low wallet shows the order with the server text', () async {
      repository.onAccept = () async => throw const SharedOrderException(
        'يرجى شحن محفظتك أولاً',
        statusCode: 403,
        walletTooLow: true,
      );

      await cubit.open();

      final state = cubit.state as SharedOrderLoaded;
      expect(state.walletMessage, 'يرجى شحن محفظتك أولاً');
      expect(state.preview.rideId, 24);
      // Refused, not offline: it is not asked again behind the driver's back.
      expect(repository.acceptCalls, 1);
    });

    test('an accept with no answer keeps the order and allows a retry', () async {
      repository.onAccept = () async => throw const SharedOrderException('offline');
      await cubit.load();
      await cubit.accept();
      final state = cubit.state as SharedOrderLoaded;
      expect(state.accepting, isFalse);
      expect(state.acceptError, 'offline');
      expect(state.preview.canAccept, isTrue);
    });

    test('tapping Accept twice sends one request', () async {
      final answer = Completer<DriverActiveRideModel?>();
      repository.onAccept = () => answer.future;
      await cubit.load();
      unawaited(cubit.accept());
      unawaited(cubit.accept());
      answer.complete(_acceptedRide());
      await pumpEventQueue();
      expect(repository.acceptCalls, 1);
      expect(cubit.state, isA<SharedOrderAccepted>());
    });

    test('a taken event during our own accept waits for its answer', () async {
      final answer = Completer<DriverActiveRideModel?>();
      repository.onAccept = () => answer.future;
      await cubit.load();
      unawaited(cubit.accept());
      closed.add({'ride_id': 24, 'reason': 'taken', 'taken_by_you': true});
      await pumpEventQueue();
      expect((cubit.state as SharedOrderLoaded).accepting, isTrue);
      answer.complete(_acceptedRide());
      await pumpEventQueue();
      expect(cubit.state, isA<SharedOrderAccepted>());
    });

    test('taken by this driver elsewhere goes back to the open trip', () async {
      await cubit.load();
      openTrips.open(24);
      closed.add({'ride_id': 24, 'reason': 'taken', 'taken_by_you': true});
      await pumpEventQueue();
      expect(cubit.state, isA<SharedOrderBackToTrip>());
    });

    test('an office edit and a socket reconnect fetch the order again', () async {
      await cubit.load();
      repository.previews
        ..clear()
        ..add(() async => SharedOrderPreviewModel.fromJson(_previewJson(pickupAddress: 'New place')));
      updated.add({'ride_id': 24});
      await pumpEventQueue();
      expect((cubit.state as SharedOrderLoaded).preview.order.pickupAddress, 'New place');

      final callsBefore = repository.previewCalls;
      connected.add(null);
      await pumpEventQueue();
      expect(repository.previewCalls, callsBefore + 1);
    });

    test('opening the link accepts at once, without a preview first', () async {
      await cubit.open();
      expect((cubit.state as SharedOrderAccepted).ride.order.rideId, 24);
      expect(repository.acceptCalls, 1);
      expect(repository.previewCalls, 0);
      expect(openTrips.openRideId, 24);
    });

    test('opening a taken order shows it as taken', () async {
      repository.onAccept = () async => throw const SharedOrderException(
        'taken',
        statusCode: 409,
        availability: SharedOrderAvailability.taken,
      );
      repository.previews
        ..clear()
        ..add(() async => _preview(availability: 'taken', canAccept: false));
      await cubit.open();
      final state = cubit.state as SharedOrderClosed;
      expect(state.availability, SharedOrderAvailability.taken);
      expect(state.preview?.rideId, 24);
    });

    test('opening while busy shows the order without accepting again', () async {
      repository.onAccept = () async => throw const SharedOrderException(
        'busy',
        statusCode: 409,
        availability: SharedOrderAvailability.busy,
      );
      repository.previews
        ..clear()
        ..add(() async => _preview(availability: 'busy', canAccept: false));
      await cubit.open();
      expect((cubit.state as SharedOrderLoaded).preview.availability, SharedOrderAvailability.busy);
      expect(repository.acceptCalls, 1);
    });

    test('an opening accept with no answer is tried once more after the fetch', () async {
      var calls = 0;
      repository.onAccept = () async {
        if (++calls == 1) throw const SharedOrderException('offline');
        return _acceptedRide();
      };
      await cubit.open();
      expect(repository.acceptCalls, 2);
      expect(cubit.state, isA<SharedOrderAccepted>());
    });

    test('opening an invalid link says so', () async {
      repository.onAccept =
          () async => throw const SharedOrderException('nope', statusCode: 404);
      await cubit.open();
      expect(cubit.state, isA<SharedOrderInvalidLink>());
    });

    test('opening an order whose trip screen is open goes back to it', () async {
      openTrips.open(24);
      await cubit.open();
      expect(cubit.state, isA<SharedOrderBackToTrip>());
    });

    test('a reconnect or taken event during the opening accept waits for it', () async {
      final answer = Completer<DriverActiveRideModel?>();
      repository.onAccept = () => answer.future;
      unawaited(cubit.open());
      connected.add(null);
      closed.add({'ride_id': 24, 'reason': 'taken', 'taken_by_you': true});
      await pumpEventQueue();
      expect(repository.previewCalls, 0);
      expect(cubit.state, isA<SharedOrderLoading>());
      answer.complete(_acceptedRide());
      await pumpEventQueue();
      expect(cubit.state, isA<SharedOrderAccepted>());
    });

    test('a refresh that fails keeps the order on screen', () async {
      await cubit.load();
      repository.previews
        ..clear()
        ..add(() async => throw const SharedOrderException('offline'));
      await cubit.load();
      expect(cubit.state, isA<SharedOrderLoaded>());
    });
  });
}

class _FakeRemoteDataSource extends Fake implements SharedOrderRemoteDataSource {
  final Object error;

  _FakeRemoteDataSource(this.error);

  @override
  Future<DriverActiveRideModel?> accept(String token) async => throw error;
}

void _repositoryTests() {
  group('SharedOrderRepository wallet refusal', () {
    DioException refusal(ApiException exception) => DioException(
      requestOptions: RequestOptions(path: '/api/driver/rides/shared/$_token/accept'),
      error: exception,
    );

    test('a 403 with errors.wallet_balance becomes walletTooLow with the server text', () async {
      final repository = SharedOrderRepository(_FakeRemoteDataSource(refusal(
        const ApiException(
          'يرجى شحن محفظتك أولاً',
          statusCode: 403,
          rawErrors: {'wallet_balance': 'يرجى شحن محفظتك أولاً'},
        ),
      )));

      await expectLater(
        repository.accept(_token),
        throwsA(
          isA<SharedOrderException>()
              .having((e) => e.walletTooLow, 'walletTooLow', isTrue)
              .having((e) => e.message, 'message', 'يرجى شحن محفظتك أولاً')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('any other 403 is not a wallet refusal', () async {
      final repository = SharedOrderRepository(_FakeRemoteDataSource(refusal(
        const ApiException('no', statusCode: 403, rawErrors: {'availability': 'busy'}),
      )));

      await expectLater(
        repository.accept(_token),
        throwsA(isA<SharedOrderException>().having((e) => e.walletTooLow, 'walletTooLow', isFalse)),
      );
    });
  });
}
