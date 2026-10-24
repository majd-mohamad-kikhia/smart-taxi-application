import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mshoar/core/account_block/account_block_cubit.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import 'package:mshoar/core/saved_addresses/presentation/cubit/saved_addresses_state.dart';
import 'package:mshoar/core/services/current_location_service.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/core/geo/geo_models.dart';
import 'package:mshoar/features/home/data/pin_label_resolver.dart';
import 'package:mshoar/features/home/data/repositories/places_repository.dart';
import 'package:mshoar/features/home/data/repositories/ride_request_repository.dart';
import 'package:mshoar/features/home/presentation/cubit/home_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/home_state.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_cubit.dart';
import 'package:mshoar/features/home/presentation/cubit/map_pick_state.dart';
import 'package:mshoar/features/home/presentation/widgets/home_bottom_panel_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_geo.dart';

const _homePoint = PickedLocationModel(
  latitude: 35.52,
  longitude: 35.79,
  address: 'شارع بغداد، اللاذقية',
);
const _workPoint = PickedLocationModel(
  latitude: 35.53,
  longitude: 35.8,
  address: 'شارع الثورة، اللاذقية',
);
const _airportName = 'مطار باسل الأسد الدولي';
const _airportSuggestion = GeoSuggestionModel(
  aliasId: 5,
  text: _airportName,
  lat: 35.4011,
  lng: 35.9487,
);
const _airportFound = GeoResolved(
  aliasId: 5,
  text: _airportName,
  lat: 35.4011,
  lng: 35.9487,
);

class _FakeAccountBlock extends Fake implements AccountBlockCubit {}

class _FakeRides extends Fake implements RideRequestRepository {}

class _Location extends CurrentLocationService {
  @override
  Future<Position?> getPositionIfAllowed() async => null;

  @override
  Future<Position?> getPositionAskingOnce() async => null;
}

/// A home cubit whose state a test can set.
class _TestHome extends HomeCubit {
  _TestHome(PlacesRepository places)
    : super(
        SessionCubit(),
        _FakeRides(),
        _FakeAccountBlock(),
        _Location(),
        places,
      );

  void show(HomeState state) => emit(state);
}

class _FakeSaved extends Cubit<SavedAddressesState>
    implements SavedAddressesCubit {
  _FakeSaved() : super(const SavedAddressesState(isLoaded: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeGeo geo;
  late PlacesRepository places;
  late _TestHome home;
  late MapPickCubit pick;
  late _FakeSaved saved;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    geo = FakeGeo()
      ..suggestions = [_airportSuggestion]
      ..resolveResult = _airportFound;
    places = PlacesRepository(
      geo,
      PinLabelResolver(geo.reverse, minGap: Duration.zero),
    );
    home = _TestHome(places);
    pick = MapPickCubit(places, _Location());
    saved = _FakeSaved();
  });

  tearDown(() async {
    await home.close();
    await pick.close();
    await saved.close();
  });

  /// Lets the cubits' streams deliver, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(800, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: ThemeData(extensions: [AppPalette.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeCubit>.value(value: home),
            BlocProvider<MapPickCubit>.value(value: pick),
            BlocProvider<SavedAddressesCubit>.value(value: saved),
          ],
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: HomeBottomPanelWidget(),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  void showPoints({PickedLocationModel? from, PickedLocationModel? to}) {
    home.show(HomeState.initial().copyWith(fromLocation: from, toLocation: to));
  }

  Finder fromField() => find.byType(TextField).first;
  Finder toField() => find.byType(TextField).last;
  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;
  bool hasFocus(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).focusNode!.hasFocus;

  group('the From and To fields', () {
    testWidgets('show the two points, and there is no other search box', (
      tester,
    ) async {
      showPoints(from: _homePoint, to: _workPoint);
      await pump(tester);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(textOf(tester, fromField()), _homePoint.address);
      expect(textOf(tester, toField()), _workPoint.address);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
    });

    testWidgets('an empty point says what to choose', (tester) async {
      await pump(tester);
      expect(textOf(tester, fromField()), isEmpty);
      expect(find.text('Choose pickup point'), findsOneWidget);
      expect(find.text('Choose your destination'), findsOneWidget);
    });

    testWidgets('a point changing from outside is shown in its field', (
      tester,
    ) async {
      await pump(tester);

      showPoints(from: _homePoint);
      await settle(tester);
      expect(textOf(tester, fromField()), _homePoint.address);
    });

    testWidgets('fit a narrow Arabic phone screen', (tester) async {
      showPoints(from: _homePoint, to: _workPoint);
      await pump(
        tester,
        locale: const Locale('ar'),
        size: const Size(640, 1200),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(toField());
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('tapping a field', () {
    testWidgets('makes it the point being placed and opens it for typing', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(toField());
      await settle(tester);

      expect(pick.state.target, PickTarget.to);
      expect(hasFocus(tester, toField()), isTrue);
      // The customer is about to type: the spot under the pin is not named.
      expect(geo.reversed, isEmpty);
      expect(find.text('Confirm location'), findsOneWidget);
    });

    testWidgets(
      'a point already chosen keeps its address and has its text selected',
      (tester) async {
        showPoints(from: _homePoint);
        await pump(tester);

        await tester.tap(fromField());
        await settle(tester);

        expect(pick.state.target, PickTarget.from);
        expect(textOf(tester, fromField()), _homePoint.address);
        final selection = tester
            .widget<TextField>(fromField())
            .controller!
            .selection;
        expect(selection.start, 0);
        expect(selection.end, _homePoint.address!.length);
      },
    );

    testWidgets('the other field takes over', (tester) async {
      showPoints(from: _homePoint, to: _workPoint);
      await pump(tester);

      await tester.tap(toField());
      await settle(tester);
      await tester.tap(fromField());
      await settle(tester);

      expect(pick.state.target, PickTarget.from);
      expect(hasFocus(tester, fromField()), isTrue);
    });

    testWidgets(
      'the map button opens the point on the map without the keyboard',
      (tester) async {
        showPoints(from: _homePoint, to: _workPoint);
        await pump(tester);

        await tester.tap(find.byIcon(Icons.pin_drop_outlined).first);
        await settle(tester);

        expect(pick.state.target, PickTarget.from);
        expect(hasFocus(tester, fromField()), isFalse);
        expect(textOf(tester, fromField()), _homePoint.address);
      },
    );

    testWidgets('while a point is locked the fields only show', (tester) async {
      home.show(
        HomeState.initial().copyWith(
          fromLocation: _homePoint,
          toLocation: _workPoint,
          isSearching: true,
        ),
      );
      await pump(tester);

      expect(tester.widget<TextField>(toField()).readOnly, isTrue);
      expect(find.byIcon(Icons.pin_drop_outlined), findsNothing);
      await tester.tap(toField());
      await settle(tester);
      expect(pick.state.isPicking, isFalse);
    });
  });

  /// What the customer types, called from the test's own zone: `enterText`
  /// and the keyboard's actions are delivered by the platform in another
  /// zone, where the cubit's pause timer would not follow the test's clock.
  Future<void> typed(WidgetTester tester, String text) async {
    tester.widget<TextField>(toField()).controller!.text = text;
    pick.queryChanged(text);
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  Future<void> submitted(WidgetTester tester) async {
    final box = tester.widget<TextField>(toField());
    box.onSubmitted!(box.controller!.text);
    await settle(tester);
  }

  group('searching from the field', () {
    testWidgets('typing asks for suggestions only, never resolves', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);

      await typed(tester, 'مطار');

      expect(geo.suggested, ['مطار']);
      expect(geo.resolved, isEmpty);
    });

    testWidgets('the search key resolves the text and puts the pin there', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);
      await typed(tester, 'مطار');

      await submitted(tester);

      expect(geo.resolved.single.q, 'مطار');
      expect(pick.state.address, _airportName);
    });

    testWidgets('the search button in the field submits too', (tester) async {
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);
      await typed(tester, 'مطار');

      await tester.tap(find.byIcon(Icons.search_rounded));
      await settle(tester);

      expect(geo.resolved.single.q, 'مطار');
    });

    testWidgets('typing is not overwritten by the map settling', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);
      await typed(tester, 'مطار');

      // The keyboard resizes the map: it settles without being dragged.
      pick.onCameraIdle(35.5, 35.78);
      await settle(tester);

      expect(textOf(tester, toField()), 'مطار');
    });

    testWidgets('the clear button empties the field and keeps it open', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);
      await typed(tester, 'مطار');

      await tester.tap(find.byIcon(Icons.close_rounded));
      await settle(tester);

      expect(textOf(tester, toField()), isEmpty);
      expect(hasFocus(tester, toField()), isTrue);
    });
  });

  group('the pin and the field', () {
    testWidgets(
      'the address under the pin is the text of the field being placed',
      (tester) async {
        await pump(tester);

        await tester.tap(find.byIcon(Icons.pin_drop_outlined).last);
        await settle(tester);
        expect(textOf(tester, toField()), 'شارع القدس، الدباغة');

        // The map is dragged and settles somewhere else.
        geo.reverseLabel = 'شارع الجمهورية';
        pick.onCameraMoveStarted();
        pick.onCameraMove(35.6, 35.9);
        await settle(tester);
        expect(
          textOf(tester, toField()),
          isEmpty,
          reason: 'the old address is gone while the pin moves',
        );

        pick.onCameraIdle(35.6, 35.9);
        await settle(tester);
        expect(textOf(tester, toField()), 'شارع الجمهورية');
      },
    );

    testWidgets('confirming puts the point in the field and ends the mode', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.pin_drop_outlined).last);
      await settle(tester);

      await tester.tap(find.text('Confirm location'));
      await settle(tester);

      expect(pick.state.isPicking, isFalse);
      expect(home.state.toLocation?.address, 'شارع القدس، الدباغة');
      expect(textOf(tester, toField()), 'شارع القدس، الدباغة');
      expect(find.text('Confirm location'), findsNothing);
    });

    testWidgets('a field left without confirming shows its own point again', (
      tester,
    ) async {
      showPoints(from: _homePoint, to: _workPoint);
      await pump(tester);
      await tester.tap(toField());
      await settle(tester);
      await typed(tester, 'نص غير مؤكد');

      pick.cancel();
      await settle(tester);

      expect(textOf(tester, toField()), _workPoint.address);
    });
  });

  group('the keyboard', () {
    testWidgets('stays when the map flies to the point that was opened', (
      tester,
    ) async {
      showPoints(from: _homePoint);
      await pump(tester);
      await tester.tap(fromField());
      await settle(tester);

      expect(hasFocus(tester, fromField()), isTrue, reason: 'after tap');
      // What the map does after opening a point: it moves there, and settles.
      pick.onCameraMoveStarted();
      await settle(tester);
      expect(
        hasFocus(tester, fromField()),
        isTrue,
        reason: 'after move started',
      );
      pick.onCameraMove(35.52, 35.79);
      await settle(tester);
      expect(hasFocus(tester, fromField()), isTrue);
      pick.onCameraIdle(35.52, 35.79);
      await settle(tester);
      expect(hasFocus(tester, fromField()), isTrue);
    });

    testWidgets('goes away when the customer drags the map', (tester) async {
      showPoints(from: _homePoint);
      await pump(tester);
      await tester.tap(fromField());
      await settle(tester);
      pick.onCameraMoveStarted();
      pick.onCameraIdle(35.52, 35.79);
      await settle(tester);

      pick.onCameraMoveStarted();
      await settle(tester);

      expect(hasFocus(tester, fromField()), isFalse);
    });
  });

  group('the buttons under the card', () {
    testWidgets('Search waits for both points, then asks for the prices', (
      tester,
    ) async {
      await pump(tester);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Search'),
            )
            .onPressed,
        isNull,
      );

      showPoints(from: _homePoint, to: _workPoint);
      await settle(tester);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Search'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });
}
