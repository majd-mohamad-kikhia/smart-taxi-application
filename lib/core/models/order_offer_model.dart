import 'package:equatable/equatable.dart';

/// A ride available for the driver to accept — pushed over the
/// `driver:orders_snapshot` / `driver:order_offer` socket events (see
/// docs/socket.md). Never fetched over REST — there is no list endpoint,
/// only the per-ride accept/pickup/start/finish/cancel actions.
///
/// Lives in `core` (not `driver_features/driver_home`, which created it)
/// because `driver_features/driver_trip` also needs it once the driver
/// accepts — see the "move to core" rule for cross-feature types.
class OrderOfferModel extends Equatable {
  final int rideId;
  final int vehicleTypeId;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double distanceKm;
  final int estimatedDurationMin;
  final double estimatedPrice;
  final bool priceIsEstimate;
  final DateTime requestedAt;
  final double distanceToPickupKm;

  const OrderOfferModel({
    required this.rideId,
    required this.vehicleTypeId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.estimatedPrice,
    required this.priceIsEstimate,
    required this.requestedAt,
    required this.distanceToPickupKm,
  });

  factory OrderOfferModel.fromJson(Map<String, dynamic> json) {
    return OrderOfferModel(
      rideId: json['ride_id'] as int,
      vehicleTypeId: json['vehicle_type_id'] as int,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedDurationMin: json['estimated_duration_min'] as int,
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
      priceIsEstimate: json['price_is_estimate'] as bool? ?? true,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      distanceToPickupKm: (json['distance_to_pickup_km'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        rideId,
        vehicleTypeId,
        pickupLat,
        pickupLng,
        pickupAddress,
        dropoffLat,
        dropoffLng,
        dropoffAddress,
        distanceKm,
        estimatedDurationMin,
        estimatedPrice,
        priceIsEstimate,
        requestedAt,
        distanceToPickupKm,
      ];
}
