import 'package:equatable/equatable.dart';
import '../../../../core/models/route_point_model.dart';

/// What the driver's home map shows: where the driver is, and the road of
/// the offer being looked at ([routeRideId]) from its pickup to its drop-off.
class DriverHomeMapState extends Equatable {
  final double? driverLat;
  final double? driverLng;

  /// The offer [orderRoute] belongs to; null when no offer is selected.
  final int? routeRideId;

  /// The road from the pickup to the drop-off. Empty while it loads or when
  /// no road could be found — the map then draws a straight dashed line.
  final List<RoutePointModel> orderRoute;

  const DriverHomeMapState({
    this.driverLat,
    this.driverLng,
    this.routeRideId,
    this.orderRoute = const [],
  });

  bool get hasDriverPosition => driverLat != null && driverLng != null;

  DriverHomeMapState copyWith({
    double? driverLat,
    double? driverLng,
    int? routeRideId,
    List<RoutePointModel>? orderRoute,
    bool clearRoute = false,
  }) {
    return DriverHomeMapState(
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      routeRideId: clearRoute ? null : (routeRideId ?? this.routeRideId),
      orderRoute: clearRoute ? const [] : (orderRoute ?? this.orderRoute),
    );
  }

  @override
  List<Object?> get props => [driverLat, driverLng, routeRideId, orderRoute];
}
