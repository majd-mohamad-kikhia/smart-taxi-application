import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';

Map<String, dynamic> _json([Map<String, dynamic> extra = const {}]) => {
  'ride_id': 1070,
  'vehicle_type_id': 9,
  'pickup_lat': 35.5,
  'pickup_lng': 35.8,
  'dropoff_lat': 35.6,
  'dropoff_lng': 35.9,
  'distance_km': 3.0,
  'estimated_duration_min': 8,
  'estimated_price': 350,
  'requested_at': '2026-11-07T17:00:00Z',
  'distance_to_pickup_km': 1.2,
  ...extra,
};

void main() {
  test('reads the name of the ordered car type', () {
    final order = OrderOfferModel.fromJson(
      _json({'vehicle_type_name': 'سياحية عامة'}),
    );
    expect(order.vehicleTypeName, 'سياحية عامة');
  });

  test('a missing, null or blank name is null (never the id)', () {
    expect(OrderOfferModel.fromJson(_json()).vehicleTypeName, isNull);
    expect(
      OrderOfferModel.fromJson(_json({'vehicle_type_name': null})).vehicleTypeName,
      isNull,
    );
    expect(
      OrderOfferModel.fromJson(_json({'vehicle_type_name': '  '})).vehicleTypeName,
      isNull,
    );
  });

  test('the name survives an eta update and a details update', () {
    final order = OrderOfferModel.fromJson(_json({'vehicle_type_name': 'اقتصادي'}));
    expect(order.withPickupEta(null).vehicleTypeName, 'اقتصادي');
    expect(order.withPassengersCount(3).vehicleTypeName, 'اقتصادي');
  });
}
