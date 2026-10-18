import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/injection/injection.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/models/driving_route_model.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/services/google_routes_service.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/driver_socket_service.dart';
import 'package:mshoar/driver_features/driver_home/data/datasources/new_order_alert.dart';
import 'package:mshoar/driver_features/driver_home/data/location_ticker.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_home_map_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_orders_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_cubit.dart';
import 'package:mshoar/driver_features/driver_home/presentation/cubit/driver_presence_state.dart';
import 'package:mshoar/driver_features/driver_home/presentation/widgets/driver_home_map_widget.dart';
import 'package:mshoar/driver_features/driver_home/presentation/widgets/driver_orders_panel_widget.dart';

class _FakeSocket extends Fake implements DriverSocketService {
  void Function(Map<String, dynamic>)? offer;

  @override
  void setOrderListeners({
    required void Function(Map<String, dynamic> data) onOrdersSnapshot,
    required void Function(Map<String, dynamic> data) onOrderOffer,
    required void Function(Map<String, dynamic> data) onOrderRemove,
  }) {
    offer = onOrderOffer;
  }
}

class _Presence extends Cubit<DriverPresenceState>
    implements DriverPresenceCubit {
  _Presence(DriverPresenceStatus status)
    : super(DriverPresenceState(status: status));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentAlert implements NewOrderAlert {
  @override
  Future<void> start({OrderOfferModel? order}) async {}

  @override
  Future<void> stop() async {}
}

class _FakeLocation extends Fake implements CurrentLocationService {
  @override
  Future<Position?> getPositionIfAllowed() async => null;
}

class _FakeTicker extends Fake implements LocationTicker {
  @override
  Stream<Position> get positions => const Stream.empty();

  @override
  Position? get lastPosition => null;
}

class _FakeRoutes extends Fake implements GoogleRoutesService {
  @override
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => Completer<DrivingRouteModel>().future;
}

Map<String, dynamic> _offer(int rideId, {String? note}) => {
  'ride_id': rideId,
  'vehicle_type_id': 2,
  'pickup_lat': 33.5 + rideId / 100,
  'pickup_lng': 36.3,
  'pickup_address': 'Pickup $rideId',
  'dropoff_lat': 33.4,
  'dropoff_lng': 36.5,
  'dropoff_address': 'Dropoff $rideId',
  'distance_km': 1.4,
  'estimated_duration_min': 4,
  'estimated_price': 284,
  'requested_at': '2026-10-03T09:12:44Z',
  'distance_to_pickup_km': 0.8,
  'note': ?note,
};

/// Lets the cubits' streams deliver, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late _FakeSocket socket;
  late DriverOrdersCubit orders;

  Future<void> setUpCubits(DriverPresenceStatus status) async {
    await sl.reset();
    socket = _FakeSocket();
    final presence = _Presence(status);
    orders = DriverOrdersCubit(
      socket,
      _FakeLocation(),
      presence,
      _SilentAlert(),
    );
    sl
      ..registerSingleton<DriverPresenceCubit>(presence)
      ..registerSingleton<DriverOrdersCubit>(orders);
  }

  tearDown(() async {
    await orders.close();
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester, Widget child, Locale locale) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: ThemeData(extensions: [AppPalette.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no offers: a short note says what the app waits for', (
    tester,
  ) async {
    await setUpCubits(DriverPresenceStatus.online);
    await pump(tester, const DriverOrdersPanelWidget(), const Locale('en'));

    expect(find.text('Waiting for new trip requests...'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('offline says to go online', (tester) async {
    await setUpCubits(DriverPresenceStatus.offline);
    await pump(tester, const DriverOrdersPanelWidget(), const Locale('en'));

    expect(find.text('Go online to see trip requests'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('offers: the card in view, and the arrows move between them '
        '(${locale.languageCode})', (tester) async {
      await setUpCubits(DriverPresenceStatus.online);
      await pump(tester, const DriverOrdersPanelWidget(), locale);
      socket.offer!(_offer(1));
      socket.offer!(_offer(2, note: 'two suitcases'));
      await settle(tester);

      // The newest offer is in view, with its addresses and its note.
      expect(find.text('Pickup 2'), findsOneWidget);
      expect(find.text('Dropoff 2'), findsOneWidget);
      expect(find.text('Pickup 1'), findsNothing);
      expect(orders.state.selectedOrder?.rideId, 2);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await settle(tester);

      expect(find.text('Pickup 1'), findsOneWidget);
      expect(find.text('Pickup 2'), findsNothing);
      expect(orders.state.selectedOrder?.rideId, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('one offer has no pager', (tester) async {
    await setUpCubits(DriverPresenceStatus.online);
    await pump(tester, const DriverOrdersPanelWidget(), const Locale('en'));
    socket.offer!(_offer(1));
    await settle(tester);

    expect(find.text('Pickup 1'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
  });

  testWidgets('the map draws and frames an offer without errors', (
    tester,
  ) async {
    await setUpCubits(DriverPresenceStatus.online);
    final map = DriverHomeMapCubit(
      _FakeTicker(),
      _FakeLocation(),
      orders,
      _FakeRoutes(),
    );
    addTearDown(map.close);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppPalette.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DriverHomeMapCubit>.value(
          value: map,
          child: const Scaffold(
            body: DriverHomeMapWidget(topInset: 120, bottomInset: 300),
          ),
        ),
      ),
    );
    await tester.pump();
    socket.offer!(_offer(1));
    await settle(tester);
    socket.offer!(_offer(2));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
