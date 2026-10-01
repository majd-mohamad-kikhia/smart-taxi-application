import 'package:equatable/equatable.dart';

/// A single location picked on the map (pickup or dropoff).
///
/// Field names deliberately echo the request body's
/// `pickup_lat`/`pickup_lng`/`pickup_address` shape used by both the
/// customer order flow (`features/home`) and ride tracking
/// (`features/tracking`) — shared across features, so it lives in `core`.
/// [address] is resolved client-side via Google's Geocoding/Places APIs
/// (`PlacesRepository`) — the backend itself still has no
/// reverse-geocoding endpoint.
class PickedLocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const PickedLocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  /// The resolved place name/address when available, falling back to
  /// coordinates rounded to 5 decimal places (~1m precision) when a
  /// reverse-geocode lookup hasn't resolved one.
  String get displayLabel =>
      address ??
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  @override
  List<Object?> get props => [latitude, longitude, address];
}
