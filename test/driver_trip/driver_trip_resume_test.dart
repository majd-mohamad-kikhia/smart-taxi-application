import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_active_ride_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/recorded_route_point_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/route_distance_calculator.dart';

RecordedRoutePointModel _point(double lat, double lng) =>
    RecordedRoutePointModel(
      lat: lat,
      lng: lng,
      recordedAt: DateTime.utc(2026, 1, 1),
    );

Map<String, dynamic> _ride(String status) => {
  'id': 42,
  'status': status,
  'vehicle_type_id': 1,
  'pickup_lat': 32.89,
  'pickup_lng': 13.18,
  'dropoff_lat': 32.90,
  'dropoff_lng': 13.28,
  'requested_at': '2026-09-30 15:30:00',
};

void main() {
  group('RouteDistanceCalculator', () {
    test('no points or a single point is zero', () {
      expect(RouteDistanceCalculator.meters([]), 0);
      expect(RouteDistanceCalculator.meters([_point(32.0, 13.0)]), 0);
    });

    test('0.01 degrees of latitude is about 1.11 km', () {
      final meters = RouteDistanceCalculator.meters([
        _point(32.00, 13.0),
        _point(32.01, 13.0),
      ]);
      expect(meters, closeTo(1112, 10));
    });

    test('sums every leg of the route', () {
      final oneLeg = RouteDistanceCalculator.meters([
        _point(32.00, 13.0),
        _point(32.01, 13.0),
      ]);
      final twoLegs = RouteDistanceCalculator.meters([
        _point(32.00, 13.0),
        _point(32.01, 13.0),
        _point(32.02, 13.0),
      ]);
      expect(twoLegs, closeTo(oneLeg * 2, 1));
    });
  });

  group('DriverActiveRideModel.tryParse', () {
    test('accepts accepted, arrived and in_progress', () {
      expect(
        DriverActiveRideModel.tryParse(_ride('accepted'))!.isArrived,
        isFalse,
      );
      expect(
        DriverActiveRideModel.tryParse(_ride('arrived'))!.isArrived,
        isTrue,
      );
      expect(
        DriverActiveRideModel.tryParse(_ride('in_progress'))!.isInProgress,
        isTrue,
      );
    });

    test('ignores rides that are over', () {
      expect(DriverActiveRideModel.tryParse(_ride('completed')), isNull);
      expect(DriverActiveRideModel.tryParse(_ride('cancelled')), isNull);
    });

    test('withRoute keeps the ride and attaches the saved points', () {
      final ride = DriverActiveRideModel.tryParse(_ride('in_progress'))!;
      final withRoute = ride.withRoute([
        _point(32.0, 13.0),
        _point(32.1, 13.0),
      ]);
      expect(withRoute.order.rideId, 42);
      expect(withRoute.isInProgress, isTrue);
      expect(withRoute.resumedRoute, hasLength(2));
    });
  });
}
