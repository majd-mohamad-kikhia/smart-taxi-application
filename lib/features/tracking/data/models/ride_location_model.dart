import 'package:equatable/equatable.dart';

/// A GPS pin — either the `location` field on `customer:ride_accepted` /
/// `customer:active_ride`, or a `customer:driver_location` tick (see
/// docs/socket.md; both share the same `lat`/`lng`/`updated_at` shape).
class RideLocationModel extends Equatable {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const RideLocationModel({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory RideLocationModel.fromJson(Map<String, dynamic> json) {
    return RideLocationModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [lat, lng, updatedAt];
}
