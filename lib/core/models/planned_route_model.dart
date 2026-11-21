import 'package:equatable/equatable.dart';
import '../utils/polyline_decoder.dart';
import 'driving_route_model.dart';
import 'route_point_model.dart';

/// The trip's one fixed road, pickup to drop-off, worked out once by the
/// server when the order is created (`planned_route`): both apps only draw
/// it. It never changes while the car moves; it is replaced only when a new
/// `planned_route` arrives (the office moved a point).
class PlannedRouteModel extends Equatable {
  /// Google-encoded polyline (precision 5), as the server sent it.
  final String polyline;
  final List<RoutePointModel> points;

  /// Road distance and travel time, for display (they do not change the price).
  final double? distanceKm;
  final int? durationMin;
  final String? provider;

  const PlannedRouteModel({
    required this.polyline,
    required this.points,
    this.distanceKm,
    this.durationMin,
    this.provider,
  });

  /// Null for a missing, empty or undecodable route: the caller then draws a
  /// straight line and makes no request of its own.
  static PlannedRouteModel? tryParse(Object? json) {
    if (json is! Map) return null;
    final encoded = json['polyline'];
    if (encoded is! String || encoded.isEmpty) return null;
    final List<RoutePointModel> points;
    try {
      points = PolylineDecoder.decode(encoded);
    } catch (_) {
      return null;
    }
    if (points.length < 2) return null;
    return PlannedRouteModel(
      polyline: encoded,
      points: points,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMin: (json['duration_min'] as num?)?.toInt(),
      provider: json['provider'] as String?,
    );
  }

  /// The route with its distance and time, for matching a car onto it
  /// locally (remaining distance and arrival time); null when the server
  /// gave no distance or time.
  DrivingRouteModel? get asDrivingRoute {
    final km = distanceKm, min = durationMin;
    if (km == null || min == null || km <= 0) return null;
    return DrivingRouteModel(
      points: points,
      distanceMeters: km * 1000,
      durationSeconds: min * 60.0,
    );
  }

  @override
  List<Object?> get props => [polyline, distanceKm, durationMin, provider];
}
