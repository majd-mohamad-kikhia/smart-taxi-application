import 'package:equatable/equatable.dart';

/// One vertex of a road route — a plain lat/lng so routing code stays
/// independent of any map SDK.
class RoutePointModel extends Equatable {
  final double lat;
  final double lng;

  const RoutePointModel(this.lat, this.lng);

  @override
  List<Object?> get props => [lat, lng];
}
