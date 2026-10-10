import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';

Map<String, dynamic> _json({String? expiresAt, Object? seconds}) => {
  'ride_id': 5,
  'vehicle_type_id': 1,
  'pickup_lat': 1.0,
  'pickup_lng': 1.0,
  'dropoff_lat': 2.0,
  'dropoff_lng': 2.0,
  'distance_km': 1.0,
  'estimated_duration_min': 3,
  'estimated_price': 100,
  'requested_at': '2026-10-03T09:12:44Z',
  'distance_to_pickup_km': 0.5,
  'expires_at': ?expiresAt,
  'expires_in_seconds': ?seconds,
};

void main() {
  final now = DateTime.utc(2026, 10, 7, 12, 0, 0);

  test('reads expires_at and the length of the turn', () {
    final offer = OrderOfferModel.fromJson(
      _json(
        expiresAt: DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 6))
            .toIso8601String(),
        seconds: 10,
      ),
    );
    expect(offer.offerSeconds, 10);
    final left = offer.expiresAt!.difference(DateTime.now().toUtc());
    expect(left.inSeconds, inInclusiveRange(4, 6));
  });

  test('an offer without expiry fields never expires', () {
    final offer = OrderOfferModel.fromJson(_json());
    expect(offer.expiresAt, isNull);
    expect(offer.offerSeconds, isNull);
  });

  test('without expires_at the turn counts from now', () {
    final at = OrderOfferModel.expiryOf(_json(seconds: 10), now: now);
    expect(at, now.add(const Duration(seconds: 10)));
  });

  test('a phone clock that runs behind cannot stretch the turn', () {
    // The server time is a minute ahead of this phone's clock.
    final at = OrderOfferModel.expiryOf(
      _json(
        expiresAt: now.add(const Duration(seconds: 70)).toIso8601String(),
        seconds: 10,
      ),
      now: now,
    );
    expect(at, now.add(const Duration(seconds: 10)));
  });

  test('a reconnect keeps the time really left', () {
    final at = OrderOfferModel.expiryOf(
      _json(
        expiresAt: now.add(const Duration(seconds: 4)).toIso8601String(),
        seconds: 10,
      ),
      now: now,
    );
    expect(at, now.add(const Duration(seconds: 4)));
  });
}
