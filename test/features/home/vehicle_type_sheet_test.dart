import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/models/picked_location_model.dart';
import 'package:mshoar/core/widgets/marquee_text_widget.dart';
import 'package:mshoar/features/home/data/models/ride_booking_options_model.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';
import 'package:mshoar/features/home/presentation/cubit/quote_route_cubit.dart';
import 'package:mshoar/features/home/presentation/widgets/vehicle_request_button_widget.dart';
import 'package:mshoar/features/home/presentation/widgets/vehicle_type_sheet_widget.dart';

RideQuoteModel _quote(List<VehicleTypeQuoteModel> types) => RideQuoteModel(
  distanceKm: 8.7,
  estimatedDurationMin: 14,
  vehicleTypes: types,
);

const _pickup = PickedLocationModel(
  latitude: 33.5,
  longitude: 36.3,
  address: 'Pickup street',
);
const _dropoff = PickedLocationModel(
  latitude: 33.52,
  longitude: 36.31,
  address: 'Drop-off street',
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

/// Lets [duration] pass in small steps, frame by frame like a device, for a
/// screen that never settles (a name that keeps sliding).
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 50);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

void main() {
  RideBookingOptionsModel? result;

  Future<void> open(
    WidgetTester tester,
    RideQuoteModel quote, {
    Size size = const Size(800, 1800),
    Locale locale = const Locale('en'),
    // A long name slides forever, so a test that has one cannot wait for the
    // screen to settle; it lets a fixed time pass instead.
    bool settle = true,
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
                      create: (_) => QuoteRouteCubit(),
                      child: VehicleTypeSheetWidget(
                        quote: quote,
                        pickup: _pickup,
                        dropoff: _dropoff,
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await pumpFor(tester, const Duration(seconds: 2));
    }
  }

  testWidgets('with the offer on, the pop-up comes first and closes', (
    tester,
  ) async {
    final offered = RideQuoteModel.fromJson({
      'distance_km': 8.7,
      'offer': {'active': true},
      'vehicle_types': [
        {
          'vehicle_type_id': 4,
          'name': 'VIP',
          'available': true,
          'estimated_price': 500,
        },
      ],
    });
    expect(offered.hasOffer, isTrue);

    // The pop-up's stars twinkle forever, so the screen never settles.
    await open(tester, offered, settle: false);

    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.text('You won the promotional offer with us'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Congratulations!'), findsNothing);
    expect(find.text('VIP'), findsOneWidget);
  });

  testWidgets('with the offer off there is no pop-up', (tester) async {
    await open(tester, _quote([_vip, _van]));

    expect(find.text('Congratulations!'), findsNothing);
  });

  testWidgets(
    'shows the title, the trip, the distance and every available car',
    (tester) async {
      await open(tester, _quote([_vip, _van, _off]));

      // The title, and the request button while nothing is chosen yet.
      expect(find.text('Choose vehicle type'), findsNWidgets(2));
      expect(find.textContaining('8.7'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('van'), findsOneWidget);
      // A car that is not available is not listed.
      expect(find.text('public'), findsNothing);
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
      settle: false,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Smart Taxi ... Smart Life'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a car with a picture address still shows its icon until the '
      'picture loads', (tester) async {
    const withPhoto = VehicleTypeQuoteModel(
      vehicleTypeId: 9,
      name: 'economy',
      imageUrl: '/uploads/vehicle-types/economy.webp',
      available: true,
      price: 100,
      stopsFeeTotal: 0,
    );
    await open(tester, _quote([withPhoto, _van]));
    // Tests have no network, so the picture can't load and the icon stands in.
    expect(find.byIcon(Icons.directions_car_rounded), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Smart Taxi ... Smart Life'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info icon sits on the description line, under the name', (
    tester,
  ) async {
    await open(tester, _quote([_vip, _van]));

    final name = tester.getCenter(find.text('VIP'));
    final description = tester.getCenter(find.text('Top-tier fleet'));
    final icon = tester.getCenter(
      find.byIcon(Icons.info_outline_rounded).first,
    );

    expect(
      icon.dy,
      closeTo(description.dy, 6),
      reason: 'beside the description',
    );
    expect(icon.dy, greaterThan(name.dy), reason: 'not beside the name');
  });

  testWidgets('a car with no description still has its info icon', (
    tester,
  ) async {
    await open(tester, _quote([_van]));

    expect(find.byTooltip('About this car'), findsOneWidget);
  });

  group('the price', () {
    testWidgets('is the figure and the currency, not "new"', (tester) async {
      await open(tester, _quote([_vip, _van]));

      expect(find.text('500 SYP'), findsOneWidget);
      expect(find.text('320 SYP'), findsOneWidget);
      expect(find.textContaining('new SYP'), findsNothing);
      // The old pounds stay on their own line under it.
      expect(find.text('50,000 old SYP'), findsOneWidget);
    });

    testWidgets('in Arabic it is ل.س alone, without "جديدة"', (tester) async {
      await open(tester, _quote([_vip, _van]), locale: const Locale('ar'));

      expect(find.text('500 ل.س'), findsOneWidget);
      expect(find.textContaining('جديدة'), findsNothing);
      expect(find.text('50,000 ل.س قديمة'), findsOneWidget);
    });

    testWidgets('the request button says it the same way', (tester) async {
      await open(tester, _quote([_vip, _van]));
      await tester.tap(find.text('VIP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Request VIP · 500 SYP'), findsOneWidget);
      expect(find.textContaining('new SYP'), findsNothing);
    });
  });

  group('a long car name', () {
    const longName =
        'Platinum family VIP with extra luggage space for large groups';
    const long = VehicleTypeQuoteModel(
      vehicleTypeId: 12,
      name: longName,
      available: true,
      price: 900,
      stopsFeeTotal: 0,
    );

    testWidgets('slides to be read in full, a short one does not', (
      tester,
    ) async {
      await open(tester, _quote([long, _van]), settle: false);

      // The whole name is in the card, and it moves.
      expect(find.text(longName), findsOneWidget);
      final slides = find.descendant(
        of: find.byType(MarqueeTextWidget),
        matching: find.byType(Transform),
      );
      expect(slides, findsOneWidget, reason: 'only the long name slides');

      final before = tester
          .widget<Transform>(slides)
          .transform
          .getTranslation()
          .x;
      await pumpFor(tester, const Duration(seconds: 6));
      final after = tester
          .widget<Transform>(slides)
          .transform
          .getTranslation()
          .x;
      expect(after, isNot(before));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the request button is text only: no arrow, no icon', (
    tester,
  ) async {
    await open(tester, _quote([_vip, _van]));
    await tester.tap(find.text('VIP'));
    await tester.pumpAndSettle();

    final button = find.byType(VehicleRequestButtonWidget);
    expect(
      find.descendant(of: button, matching: find.textContaining('Request VIP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: button, matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('requesting pops the chosen car and the note', (tester) async {
    await open(tester, _quote([_vip, _van]));
    await tester.tap(find.text('van'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  two suitcases ');
    await tester.pump();

    await tester.tap(find.byType(VehicleRequestButtonWidget));
    await tester.pumpAndSettle();

    expect(result?.vehicleTypeId, 3);
    expect(result?.note, 'two suitcases');
  });

  testWidgets('a single choosable car starts selected', (tester) async {
    await open(tester, _quote([_van, _off]));
    expect(find.textContaining('Request van ·'), findsOneWidget);

    await tester.tap(find.byType(VehicleRequestButtonWidget));
    await tester.pumpAndSettle();
    expect(result?.vehicleTypeId, 3);
  });

  testWidgets('an unavailable car is not listed, so it cannot be chosen', (
    tester,
  ) async {
    await open(tester, _quote([_vip, _off]));

    expect(find.text('public'), findsNothing);
    expect(find.textContaining('Request VIP ·'), findsOneWidget);
  });

  testWidgets('with no car available it says so and can be closed', (
    tester,
  ) async {
    await open(tester, _quote([_off]));
    expect(find.byType(VehicleRequestButtonWidget), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('public'), findsNothing);
  });
}
