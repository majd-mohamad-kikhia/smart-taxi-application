import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/ride_cancellation_model.dart';

void main() {
  test('parses the socket payload', () {
    final event = RideCancellationModel.fromJson({
      'ride_id': 42,
      'status': 'cancelled',
      'cancelled_by': 'customer',
      'cancellation_reason': 'Changed my plans',
    });

    expect(event?.rideId, 42);
    expect(event?.cancelledBy, RideCancelledBy.customer);
    expect(event?.reason, 'Changed my plans');
  });

  test('parses the FCM payload, where every value is a string', () {
    final event = RideCancellationModel.fromJson({
      'notification_type': 'ride_cancelled',
      'ride_id': '42',
      'cancelled_by': 'customer',
    });

    expect(event?.rideId, 42);
    expect(event?.cancelledBy, RideCancelledBy.customer);
    expect(event?.reason, isNull);
  });

  test('ignores a payload without a ride id', () {
    expect(RideCancellationModel.fromJson({'cancelled_by': 'customer'}), isNull);
  });

  test('an unknown cancelled_by is left null', () {
    final event = RideCancellationModel.fromJson({'ride_id': 1, 'cancelled_by': 'robot'});
    expect(event?.cancelledBy, isNull);
  });
}
