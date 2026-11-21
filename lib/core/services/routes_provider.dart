import '../models/driving_route_model.dart';

/// Something that can work out a road route between two points: the Google
/// Routes API or an OpenStreetMap router. [TripRouteTracker] asks one for the
/// driver's way to the customer.
abstract interface class RoutesProvider {
  /// Throws `RouteException` when no route could be found.
  Future<DrivingRouteModel> computeRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });
}
