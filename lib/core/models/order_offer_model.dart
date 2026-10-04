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

  /// Building, floor, landmark… typed by the customer or the office.
  final String? pickupAddressDetails;
  final String? dropoffAddressDetails;

  /// The customer's note for the driver ("I have two suitcases").
  final String? note;

  /// People in the car: written by the office, or by the driver when the
  /// trip starts. Null until someone wrote it.
  final int? passengersCount;

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
    this.pickupAddressDetails,
    this.dropoffAddressDetails,
    this.note,
    this.passengersCount,
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
      pickupAddressDetails: textOrNull(json['pickup_address_details']),
      dropoffAddressDetails: textOrNull(json['dropoff_address_details']),
      note: textOrNull(json['note']),
      passengersCount: countOrNull(json['passengers_count']),
    );
  }

  /// The same ride with the points, price and texts from an updated ride
  /// payload (an office edit while the driver is on the trip). Fields the
  /// payload leaves out keep their current value.
  OrderOfferModel withUpdatedDetails(Map<String, dynamic> json) {
    double numOr(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    String? textOr(String key, String? fallback) =>
        json.containsKey(key) ? textOrNull(json[key]) : fallback;
    return OrderOfferModel(
      rideId: rideId,
      vehicleTypeId: (json['vehicle_type_id'] as num?)?.toInt() ?? vehicleTypeId,
      pickupLat: numOr('pickup_lat', pickupLat),
      pickupLng: numOr('pickup_lng', pickupLng),
      pickupAddress: textOr('pickup_address', pickupAddress) ?? '',
      dropoffLat: numOr('dropoff_lat', dropoffLat),
      dropoffLng: numOr('dropoff_lng', dropoffLng),
      dropoffAddress: textOr('dropoff_address', dropoffAddress) ?? '',
      distanceKm: numOr('distance_km', distanceKm),
      estimatedDurationMin:
          (json['estimated_duration_min'] as num?)?.toInt() ?? estimatedDurationMin,
      estimatedPrice: numOr('estimated_price', estimatedPrice),
      priceIsEstimate: priceIsEstimate,
      requestedAt: requestedAt,
      distanceToPickupKm: distanceToPickupKm,
      pickupAddressDetails: textOr('pickup_address_details', pickupAddressDetails),
      dropoffAddressDetails: textOr('dropoff_address_details', dropoffAddressDetails),
      note: textOr('note', note),
      passengersCount: json.containsKey('passengers_count')
          ? countOrNull(json['passengers_count'])
          : passengersCount,
    );
  }

  /// The same ride once the number of passengers is known.
  OrderOfferModel withPassengersCount(int? count) =>
      withUpdatedDetails({'passengers_count': count});

  /// A positive whole number, or null.
  static int? countOrNull(Object? value) {
    if (value is! num) return null;
    final count = value.toInt();
    return count > 0 ? count : null;
  }

  /// A trimmed, non-empty string, or null.
  static String? textOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
        pickupAddressDetails,
        dropoffAddressDetails,
        note,
        passengersCount,
      ];
}
