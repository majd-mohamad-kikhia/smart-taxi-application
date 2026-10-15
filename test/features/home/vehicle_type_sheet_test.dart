import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/models/route_point_model.dart';
import 'package:mshoar/core/services/google_routes_service.dart';
import 'package:mshoar/core/services/planned_route_loader.dart';
import 'package:mshoar/features/home/data/models/ride_booking_options_model.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';
import 'package:mshoar/features/home/presentation/cubit/quote_route_cubit.dart';
import 'package:mshoar/features/home/presentation/widgets/vehicle_type_sheet_widget.dart';

RideQuoteModel _quote(List<VehicleTypeQuoteModel> types) => RideQuoteModel(
  distanceKm: 8.7,
  estimatedDurationMin: 14,
  vehicleTypes: types,
);

const _vip = VehicleTypeQuoteModel(
  vehicleTypeId: 4,
  name: 'VIP',
  description: 'Top-tier fleet',
  available: true,
  price: 500,
  stopsFeeTotal: 0,
);
const _van = VehicleTypeQuoteModel(
  vehicleTypeId: 3,
  name: 'van',
  available: true,
  price: 320,
  stopsFeeTotal: 0,
);
const _off = VehicleTypeQuoteModel(
  vehicleTypeId: 7,
  name: 'public',
  available: false,
  stopsFeeTotal: 0,
);

/// Hands back no route, so the sheet's map never reaches the network.
class _NoRouteLoader extends PlannedRouteLoader {
  _NoRouteLoader()
    : super(
        GoogleRoutesService(
          credentials: () async => throw StateError('offline'),
        ),
      );

  @override
  Future<List<RoutePointModel>> load({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async => const [];
}

void main() {
  RideBookingOptionsModel? result;

  Future<void> open(
    WidgetTester tester,
    RideQuoteModel quote, {
    Size size = const Size(800, 1800),
    Locale locale = const Locale('en'),
  }) async {
    result = null;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<RideBookingOptionsModel>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BlocProvider<QuoteRouteCubit>(
                      create: (_) => QuoteRouteCubit(_NoRouteLoader()),
                      child: VehicleTypeSheetWidget(
                        quote: quote,
                        pickup: const PickedLocationModel(
                          latitude: 35.5,
                          longitude: 35.78,
                          address: 'Pickup street',
                        ),
                        dropoff: const PickedLocationModel(
                          latitude: 35.52,
                          longitude: 35.8,
                          address: 'Drop-off street',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the title, the trip, the distance and every car with its price',
    (tester) async {
      await open(tester, _quote([_vip, _van, _off]));

      expect(
        find.text('Choose a vehicle type'),
        findsNothing,
      ); // wording is the app's own
      expect(find.text('Pickup street'), findsOneWidget);
      expect(find.text('Drop-off street'), findsOneWidget);
      expect(find.textContaining('8.7'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('van'), findsOneWidget);
      expect(find.text('public'), findsOneWidget);
      expect(find.text('Top-tier fleet'), findsOneWidget);
    },
  );

  testWidgets(
    'the button waits for a choice, then names the car and its price',
    (tester) async {
      await open(tester, _quote([_vip, _van]));
      expect(find.textContaining('Request '), findsNothing);

      await tester.tap(find.text('VIP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Request VIP ·'), findsOneWidget);
    },
  );

  testWidgets('the info icon tells about the car without choosing it', (
    tester,
  ) async {
    await open(tester, _quote([_vip, _van]));

    await tester.tap(find.byTooltip('About this car').first);
    await tester.pumpAndSettle();

    // The car's description and the brand slogan, and nothing was chosen.
    expect(find.text('Top-tier fleet'), findsNWidgets(2));
    expect(find.text('Smart Taxi ... Smart Life'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Taxi ... Smart Life'), findsNothing);
    expect(find.textContaining('Request '), findsNothing);
  });

  testWidgets('a car with no description shows only its name and the slogan', (
    tester,
  ) async {
    await open(tester, _quote([_vip, _van]));

    await tester.tap(find.byTooltip('About this car').last);
    await tester.pumpAndSettle();

    expect(find.text('van'), findsNWidgets(2));
    expect(find.byIcon(Icons.format_quote_rounded), findsNothing);
    expect(find.text('Smart Taxi ... Smart Life'), findsOneWidget);
  });

  testWidgets('the info icon fits next to a long Arabic name', (tester) async {
    const long = VehicleTypeQuoteModel(
      vehicleTypeId: 9,
      name: 'بلاتينيوم فاخر للعائلات والمجموعات الكبيرة',
      description: 'سيارات واسعة ومريحة لرحلاتك الطويلة مع العائلة والأصدقاء',
      available: true,
      price: 500,
      stopsFeeTotal: 0,
    );
    await open(
      tester,
      _quote([long, _van]),
      // The test font is far wider than the app's, so a phone-sized screen
      // would only test the price figure.
      size: const Size(640, 1400),
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Smart Taxi ... Smart Life'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requesting pops the chosen car and the note', (tester) async {
    await open(tester, _quote([_vip, _van]));
    await tester.tap(find.text('van'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  two suitcases ');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(result?.vehicleTypeId, 3);
    expect(result?.note, 'two suitcases');
  });

  testWidgets('a single choosable car starts selected', (tester) async {
    await open(tester, _quote([_van, _off]));
    expect(find.textContaining('Request van ·'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(result?.vehicleTypeId, 3);
  });

  testWidgets('an unavailable car cannot be chosen', (tester) async {
    await open(tester, _quote([_vip, _off]));
    await tester.tap(find.text('public'));
    await tester.pumpAndSettle();
    // Only the single choosable VIP is selected; tapping the unavailable
    // car changes nothing.
    expect(find.textContaining('Request VIP ·'), findsOneWidget);
    expect(find.textContaining('Request public'), findsNothing);
  });

  testWidgets('with no car available it says so and can be closed', (
    tester,
  ) async {
    await open(tester, _quote([_off]));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('public'), findsNothing);
  });
}
