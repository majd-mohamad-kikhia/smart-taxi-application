import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/models/vehicle_type_quote_model.dart';

/// The server sends a flat price per distance band, in `estimated_price`.
/// `base_fare` / `price_per_km` are sent too but must never be multiplied.
Map<String, dynamic> _type({
  num? estimatedPrice,
  num pricePerKm = 500,
  num baseFare = 0,
  bool available = true,
}) => {
  'vehicle_type_id': 3,
  'name': 'vip',
  'available': available,
  'estimated_price': estimatedPrice,
  'price_per_km': pricePerKm,
  'base_fare': baseFare,
  'stops_fee_total': 0,
};

void main() {
  test('VIP 8.7 km shows the server price 500, not 500 x distance', () {
    final type = VehicleTypeQuoteModel.fromJson(_type(estimatedPrice: 500));
    expect(type.price, 500);
  });

  test('shows exactly the numbers the server sends', () {
    expect(
      VehicleTypeQuoteModel.fromJson(
        _type(estimatedPrice: 240, pricePerKm: 240),
      ).price,
      240,
    );
    expect(
      VehicleTypeQuoteModel.fromJson(
        _type(estimatedPrice: 260, pricePerKm: 260),
      ).price,
      260,
    );
    expect(
      VehicleTypeQuoteModel.fromJson(
        _type(estimatedPrice: 200, pricePerKm: 200),
      ).price,
      200,
    );
  });

  test('a missing price stays missing: nothing is calculated', () {
    final type = VehicleTypeQuoteModel.fromJson(
      _type(estimatedPrice: null, pricePerKm: 500, baseFare: 1000),
    );
    expect(type.price, isNull);
  });

  test('an unavailable type has no price, whatever the server also sent', () {
    final type = VehicleTypeQuoteModel.fromJson(
      _type(estimatedPrice: 500, available: false),
    );
    expect(type.available, isFalse);
    expect(type.price, isNull);
  });

  test('still reads an older response that names the field price', () {
    final json = _type()..['price'] = 350;
    expect(VehicleTypeQuoteModel.fromJson(json).price, 350);
  });
}
