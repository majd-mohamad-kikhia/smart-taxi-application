import 'package:geolocator/geolocator.dart';
import 'models/recorded_route_point_model.dart';

/// Length of a recorded route: the sum of the straight-line gaps between
/// consecutive samples. Used to pick the driven distance back up after the
/// app was killed mid-trip.
///
/// Straight lines cut corners between 5 s samples, so this slightly
/// under-measures a winding road — which is why it only seeds the total on
/// resume, while a running trip keeps accumulating every GPS fix.
class RouteDistanceCalculator {
  const RouteDistanceCalculator._();

  static double meters(List<RecordedRoutePointModel> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += Geolocator.distanceBetween(
        points[i - 1].lat,
        points[i - 1].lng,
        points[i].lat,
        points[i].lng,
      );
    }
    return total;
  }
}
