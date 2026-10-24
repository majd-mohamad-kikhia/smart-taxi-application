import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/screen_takeover/data/screen_takeover_platform.dart';
import 'package:mshoar/core/screen_takeover/data/screen_takeover_store.dart';
import 'package:mshoar/core/services/local_notification_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/incoming_order_call_alert.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/new_order_alert.dart';

class _FakeNotifications extends Fake implements LocalNotificationService {
  final shown =
      <
        ({
          int id,
          String title,
          String body,
          String? payload,
          Duration timeout,
          bool fullScreenIntent,
        })
      >[];
  final cancelled = <int>[];
  bool failShow = false;

  @override
  Future<void> showIncomingOrderCall({
    required int id,
    required String title,
    required String body,
    String? payload,
    Duration timeout = const Duration(seconds: 10),
    bool fullScreenIntent = true,
  }) async {
    if (failShow) throw StateError('no notification permission');
    shown.add((
      id: id,
      title: title,
      body: body,
      payload: payload,
      timeout: timeout,
      fullScreenIntent: fullScreenIntent,
    ));
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

class _FakeTakeoverStore extends Fake implements ScreenTakeoverStore {
  bool enabled = true;

  @override
  Future<bool> isEnabled() async => enabled;
}

class _FakeTakeover extends Fake implements ScreenTakeoverPlatform {
  int broughtToFront = 0;

  @override
  Future<void> bringToFront() async => broughtToFront++;
}

class _Recording implements NewOrderAlert {
  int starts = 0;
  int stops = 0;
  bool fail = false;

  @override
  Future<void> start({OrderOfferModel? order}) async {
    starts++;
    if (fail) throw StateError('boom');
  }

  @override
  Future<void> stop() async => stops++;
}

final _order = OrderOfferModel.fromJson({
  'ride_id': 42,
  'vehicle_type_id': 2,
  'pickup_lat': 35.5,
  'pickup_lng': 35.8,
  'dropoff_lat': 35.6,
  'dropoff_lng': 35.9,
  'distance_km': 3.0,
  'estimated_duration_min': 8,
  'estimated_price': 240,
  'requested_at': '2026-10-11T10:00:00Z',
  'distance_to_pickup_km': 1.2,
});

void main() {
  late _FakeNotifications notifications;
  late _FakeTakeoverStore takeoverStore;
  late _FakeTakeover takeover;
  var foreground = false;
  late IncomingOrderCallAlert alert;

  setUp(() {
    notifications = _FakeNotifications();
    takeoverStore = _FakeTakeoverStore();
    takeover = _FakeTakeover();
    foreground = false;
    alert = IncomingOrderCallAlert(
      notifications,
      takeoverStore,
      takeover,
      isForeground: () => foreground,
    );
  });

  test('with the switch on the call takes over the screen and the app '
      'is brought to the front', () async {
    await alert.start(order: _order);

    expect(notifications.shown.single.fullScreenIntent, isTrue);
    expect(takeover.broughtToFront, 1);
  });

  test('with the switch off the call only rings: no screen takeover, '
      'the app stays where it is', () async {
    takeoverStore.enabled = false;
    await alert.start(order: _order);

    expect(notifications.shown.single.fullScreenIntent, isFalse);
    expect(takeover.broughtToFront, 0);
  });

  test('with the app on screen it is not brought to the front', () async {
    foreground = true;
    await alert.start(order: _order);
    expect(takeover.broughtToFront, 0);
  });

  test(
    'in the background a new order rings like a call, for the order\'s own turn',
    () async {
      await alert.start(order: _order);

      final call = notifications.shown.single;
      expect(call.payload, '42');
      expect(call.timeout, const Duration(seconds: 10));
      expect(call.body, contains('240'));
      expect(call.body, contains('1.2'));
    },
  );

  test('with the app on screen nothing is shown outside it', () async {
    foreground = true;
    await alert.start(order: _order);
    expect(notifications.shown, isEmpty);
  });

  test('stop clears the call, and only when one is showing', () async {
    await alert.stop();
    expect(notifications.cancelled, isEmpty);

    await alert.start(order: _order);
    await alert.stop();
    await alert.stop();
    expect(notifications.cancelled, hasLength(1));
  });

  test(
    'a newer order replaces the one ringing (same notification id)',
    () async {
      await alert.start(order: _order);
      await alert.start(order: _order);
      expect(notifications.shown.map((c) => c.id).toSet(), hasLength(1));
    },
  );

  test('a notification that cannot be shown does not throw', () async {
    notifications.failShow = true;
    await alert.start(order: _order);
    await alert.stop();
    expect(notifications.cancelled, isEmpty);
  });

  group('CompositeNewOrderAlert', () {
    test('starts and stops every alert', () async {
      final a = _Recording(), b = _Recording();
      final both = CompositeNewOrderAlert([a, b]);

      await both.start(order: _order);
      await both.stop();

      expect((a.starts, a.stops, b.starts, b.stops), (1, 1, 1, 1));
    });

    test('one failing alert does not stop the other', () async {
      final broken = _Recording()..fail = true;
      final fine = _Recording();

      await CompositeNewOrderAlert([broken, fine]).start(order: _order);

      expect(fine.starts, 1);
    });
  });
}
