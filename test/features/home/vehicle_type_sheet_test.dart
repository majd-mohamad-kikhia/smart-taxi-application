import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/features/home/data/models/ride_booking_options_model.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';
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

void main() {
  RideBookingOptionsModel? result;

  Future<void> open(WidgetTester tester, RideQuoteModel quote) async {
    result = null;
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
                    builder: (_) => VehicleTypeSheetWidget(
                      quote: quote,
                      pickupLabel: 'Pickup street',
                      dropoffLabel: 'Drop-off street',
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
      expect(find.textContaining('VIP ·'), findsNothing);

      await tester.tap(find.text('VIP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('VIP'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    },
  );

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
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(result?.vehicleTypeId, 3);
  });

  testWidgets('an unavailable car cannot be chosen', (tester) async {
    await open(tester, _quote([_vip, _off]));
    await tester.tap(find.text('public'));
    await tester.pumpAndSettle();
    expect(
      find.byIcon(Icons.check_circle_rounded),
      findsOneWidget,
    ); // only the single choosable VIP
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
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
