import 'package:equatable/equatable.dart';
import 'route_point_model.dart';

/// A road route from the routing service: the line to draw plus the road
/// distance and travel time the service computed for it.
class DrivingRouteModel extends Equatable {
  final List<RoutePointModel> points;
  final double distanceMeters;
  final double durationSeconds;

  const DrivingRouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  @override
  List<Object?> get props => [points, distanceMeters, durationSeconds];
}
