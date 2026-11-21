import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/models/planned_route_model.dart';
import 'package:mshoar/core/models/ride_model.dart';

// Google's documented example line: three points.
const _line = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

Map<String, dynamic> _plannedJson([String polyline = _line]) => {
  'polyline': polyline,
  'distance_km': 4.65,
  'duration_min': 9,
  'provider': 'osm',
};

Map<String, dynamic> _offerJson([Map<String, dynamic> extra = const {}]) => {
  'ride_id': 1,
  'vehicle_type_id': 2,
  'pickup_lat': 35.5,
  'pickup_lng': 35.8,
  'dropoff_lat': 35.6,
  'dropoff_lng': 35.9,
  'distance_km': 3.0,
  'estimated_duration_min': 8,
  'estimated_price': 240,
  'requested_at': '2026-11-10T10:00:00Z',
  'distance_to_pickup_km': 1.2,
  ...extra,
};

void main() {
  group('PlannedRouteModel.tryParse', () {
    test('decodes the line and keeps the distance, time and provider', () {
      final route = PlannedRouteModel.tryParse(_plannedJson())!;
      expect(route.points, hasLength(3));
      expect(route.distanceKm, 4.65);
      expect(route.durationMin, 9);
      expect(route.provider, 'osm');
    });

    test('null, empty or broken input is null: draw a straight line', () {
      expect(PlannedRouteModel.tryParse(null), isNull);
      expect(PlannedRouteModel.tryParse({'polyline': ''}), isNull);
      expect(PlannedRouteModel.tryParse('x'), isNull);
      expect(PlannedRouteModel.tryParse({'distance_km': 1}), isNull);
    });

    test('works as a route to match a car on, when it has distance and time', () {
      final route = PlannedRouteModel.tryParse(_plannedJson())!.asDrivingRoute!;
      expect(route.distanceMeters, 4650);
      expect(route.durationSeconds, 540);
      expect(
        PlannedRouteModel.tryParse({'polyline': _line})!.asDrivingRoute,
        isNull,
      );
    });
  });

  group('where it rides in', () {
    test('the customer ride from choose-vehicle', () {
      final ride = RideModel.fromJson({
        'id': 7,
        'status_id': 1,
        'status': 'requested',
        'planned_route': _plannedJson(),
      });
      expect(ride.plannedRoute!.points, hasLength(3));
      expect(
        RideModel.fromJson({'id': 7, 'status_id': 1, 'planned_route': null})
            .plannedRoute,
        isNull,
      );
    });

    test('an office edit replaces the line, and a payload without one keeps it', () {
      final order = OrderOfferModel.fromJson(
        _offerJson({'planned_route': _plannedJson()}),
      );
      final kept = order.withUpdatedDetails({'note': 'two bags'});
      expect(kept.plannedRoute, order.plannedRoute);

      // Another polyline: the same three points shifted by encoding a new line.
      final other = PlannedRouteModel.tryParse(_plannedJson('_ibE_seK_seK_seK'))!;
      final replaced = order.withUpdatedDetails({
        'planned_route': _plannedJson('_ibE_seK_seK_seK'),
      });
      expect(replaced.plannedRoute, other);
      expect(replaced.plannedRoute, isNot(order.plannedRoute));
    });

    test('an offer has none; the accept hands it over', () {
      final offer = OrderOfferModel.fromJson(_offerJson());
      expect(offer.plannedRoute, isNull);
      final route = PlannedRouteModel.tryParse(_plannedJson());
      expect(offer.withPlannedRoute(route).plannedRoute, route);
      expect(offer.withPlannedRoute(null).plannedRoute, isNull);
    });
  });
}
