import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/ride_fare_breakdown_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_trip_fare_model.dart';
import 'package:mshoar/features/trips/data/models/ride_history_model.dart';

Map<String, dynamic> _offer([Map<String, dynamic> extra = const {}]) => {
      'ride_id': 7,
      'vehicle_type_id': 1,
      'pickup_lat': 33.5,
      'pickup_lng': 36.3,
      'dropoff_lat': 33.6,
      'dropoff_lng': 36.4,
      'distance_km': 4.2,
      'estimated_duration_min': 12,
      'estimated_price': 320,
      'requested_at': '2026-10-05T10:00:00Z',
      'distance_to_pickup_km': 1.1,
      ...extra,
    };

void main() {
  group('OrderOfferModel.passengersFee', () {
    test('is read from the offer and is 0 when missing or negative', () {
      expect(OrderOfferModel.fromJson(_offer({'passengers_fee': 20})).passengersFee, 20);
      expect(OrderOfferModel.fromJson(_offer()).passengersFee, 0);
      expect(OrderOfferModel.fromJson(_offer({'passengers_fee': -5})).passengersFee, 0);
    });

    test('an office edit updates it only when the payload has it', () {
      final order = OrderOfferModel.fromJson(_offer({'passengers_fee': 10}));
      expect(order.withUpdatedDetails({'note': 'x'}).passengersFee, 10);
      expect(order.withUpdatedDetails({'passengers_fee': 20}).passengersFee, 20);
      expect(order.withUpdatedDetails({'passengers_fee': 0}).passengersFee, 0);
    });

    test('the active ride keeps it', () {
      final ride = DriverActiveRideModel.tryParse({
        'id': 7,
        'status': 'accepted',
        'pickup_lat': 33.5,
        'pickup_lng': 36.3,
        'dropoff_lat': 33.6,
        'dropoff_lng': 36.4,
        'passengers_count': 6,
        'passengers_fee': 20,
      });
      expect(ride!.order.passengersFee, 20);
    });
  });

  group('RideFareBreakdownModel.passengersFee', () {
    test('comes from fare.passengers_fee, with the ride count as fallback', () {
      final fare = RideFareBreakdownModel.fromParent({
        'passengers_count': 5,
        'fare': {'distance_fare': 300, 'passengers_fee': 10, 'final_price': 310},
      })!;
      expect(fare.passengersFee, 10);
      expect(fare.passengersCount, 5);
      expect(fare.finalPrice, 310);
    });

    test('is 0 for an app order', () {
      final fare = RideFareBreakdownModel.fromJson({'distance_fare': 300, 'final_price': 300});
      expect(fare.passengersFee, 0);
      expect(fare.passengersCount, isNull);
    });

    test('the driver finish reply falls back to the ride passengers_count', () {
      final fare = DriverTripFareModel.fromRideJson({
        'passengers_count': 6,
        'fare': {'distance_fare': 300, 'passengers_fee': 20, 'final_price': 320},
      });
      expect(fare.breakdown.passengersFee, 20);
      expect(fare.breakdown.passengersCount, 6);
      expect(fare.finalPrice, 320);
    });
  });

  group('RideHistoryModel.passengersFee', () {
    test('is not counted twice in the trip fare', () {
      final ride = RideHistoryModel.fromJson({
        'id': 1,
        'status_id': 5,
        'price': 320,
        'final_price': 320,
        'stops_fee_total': 0,
        'passengers_fee': 20,
        'passengers_count': 6,
      });
      expect(ride.passengersFee, 20);
      expect(ride.tripFare, 300);
      expect(ride.shownPrice, 320);
    });
  });
}
