import 'package:equatable/equatable.dart';

/// One vehicle type with its price quote for the requested trip, as
/// returned in `vehicle_types[]` by `POST /api/customer/rides/locations`.
class VehicleTypeQuoteModel extends Equatable {
  final int vehicleTypeId;
  final String name;
  final String? description;
  final bool available;
  final double? price;
  final double? baseFare;
  final double? pricePerKm;
  final double stopsFeeTotal;

  const VehicleTypeQuoteModel({
    required this.vehicleTypeId,
    required this.name,
    this.description,
    required this.available,
    this.price,
    this.baseFare,
    this.pricePerKm,
    required this.stopsFeeTotal,
  });

  factory VehicleTypeQuoteModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeQuoteModel(
      vehicleTypeId: json['vehicle_type_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      available: json['available'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble(),
      baseFare: (json['base_fare'] as num?)?.toDouble(),
      pricePerKm: (json['price_per_km'] as num?)?.toDouble(),
      stopsFeeTotal: (json['stops_fee_total'] as num?)?.toDouble() ?? 0,
    );
  }

  /// The price to show for this vehicle type. Prefers the server's
  /// [price] directly; falls back to computing it from [baseFare] /
  /// [pricePerKm] / [distanceKm] when the server sent `price: null` for
  /// an otherwise-priceable type — same formula this endpoint documents:
  /// `price = base_fare + (distance_km × price_per_km)`.
  double? displayPrice(double distanceKm) {
    if (price != null) return price;
    final baseFare = this.baseFare;
    final pricePerKm = this.pricePerKm;
    if (baseFare == null || pricePerKm == null) return null;
    return baseFare + (distanceKm * pricePerKm) + stopsFeeTotal;
  }

  @override
  List<Object?> get props => [
        vehicleTypeId,
        name,
        description,
        available,
        price,
        baseFare,
        pricePerKm,
        stopsFeeTotal,
      ];
}
