import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';
import 'package:mshoar/features/home/presentation/widgets/vehicle_type_tile_widget.dart';

/// 3.9 km from `الرمل الجنوبي`: VIP 320 + 40 = 360, comfort 250 + 30 = 280.
Map<String, dynamic> _quote({
  Object? area = const {'name': 'الرمل الجنوبي', 'fee': 40},
}) => {
  'distance_km': 3.9,
  'estimated_duration_min': 9,
  'location_fee': area,
  'vehicle_types': [
    {
      'vehicle_type_id': 2,
      'name': 'comfort',
      'available': true,
      'estimated_price': 280,
      'distance_price': 250,
      'location_fee': 30,
    },
    {
      'vehicle_type_id': 4,
      'name': 'VIP',
      'available': true,
      'estimated_price': 360,
      'distance_price': 320,
      'location_fee': 40,
    },
  ],
};

void main() {
  test(
    'each car keeps its own location fee, and the price is the server\'s',
    () {
      final quote = RideQuoteModel.fromJson(_quote());
      final comfort = quote.vehicleTypes[0];
      final vip = quote.vehicleTypes[1];

      expect((comfort.price, comfort.locationFee), (280, 30));
      expect((vip.price, vip.locationFee), (360, 40));
    },
  );

  test(
    'the area name comes from the top level; its fee (highest car) is not used',
    () {
      expect(
        RideQuoteModel.fromJson(_quote()).locationFeeName,
        'الرمل الجنوبي',
      );
    },
  );

  test('a trip that touches no listed area has no name and no fee', () {
    final json = _quote(area: null);
    for (final type in json['vehicle_types'] as List) {
      (type as Map<String, dynamic>)['location_fee'] = 0;
    }
    final quote = RideQuoteModel.fromJson(json);

    expect(quote.locationFeeName, isNull);
    expect(quote.vehicleTypes.map((t) => t.locationFee), [0, 0]);
  });

  test('an unavailable car has no fee to show', () {
    final type = VehicleTypeQuoteModel.fromJson({
      'vehicle_type_id': 4,
      'name': 'VIP',
      'available': false,
      'estimated_price': null,
      'location_fee': 40,
    });
    expect(type.locationFee, 0);
  });

  group('vehicle tile', () {
    Future<void> show(
      WidgetTester tester,
      VehicleTypeQuoteModel type, {
      String? area,
    }) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VehicleTypeTileWidget(
            vehicleType: type,
            locationFeeName: area,
            price: type.price,
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final vip = VehicleTypeQuoteModel.fromJson(
      (_quote()['vehicle_types'] as List)[1] as Map<String, dynamic>,
    );

    testWidgets('names the area and the fee included in the price', (
      tester,
    ) async {
      await show(tester, vip, area: 'الرمل الجنوبي');
      expect(find.textContaining('40'), findsWidgets);
      expect(find.textContaining('الرمل الجنوبي'), findsOneWidget);
      expect(find.textContaining('location fee'), findsOneWidget);
    });

    testWidgets('a car with no fee shows no fee line', (tester) async {
      final free = VehicleTypeQuoteModel.fromJson({
        'vehicle_type_id': 2,
        'name': 'comfort',
        'available': true,
        'estimated_price': 250,
        'location_fee': 0,
      });
      await show(tester, free);
      expect(find.textContaining('location fee'), findsNothing);
    });
  });
}
