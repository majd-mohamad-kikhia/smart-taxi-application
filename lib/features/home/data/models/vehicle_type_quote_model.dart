import 'package:equatable/equatable.dart';

/// One vehicle type with its price quote for the requested trip, as
/// returned in `vehicle_types[]` by `POST /api/customer/rides/locations`.
///
/// The price is the server's, shown as it came: the app never works one out.
/// The server charges a flat price per distance band, so `price_per_km` and
/// `base_fare` in the response are not rates to multiply by a distance and
/// are deliberately not read here.
class VehicleTypeQuoteModel extends Equatable {
  final int vehicleTypeId;
  final String name;
  final String? description;
  final bool available;

  /// The server's `estimated_price` for this trip; null when the type is not
  /// available (or the server could not quote one).
  final double? price;
  final double stopsFeeTotal;

  /// This car's fee for a pickup or drop-off in a listed area, already
  /// inside [price]. 0 when the car has none here. Shown, never added.
  final double locationFee;

  const VehicleTypeQuoteModel({
    required this.vehicleTypeId,
    required this.name,
    this.description,
    required this.available,
    this.price,
    required this.stopsFeeTotal,
    this.locationFee = 0,
  });

  factory VehicleTypeQuoteModel.fromJson(Map<String, dynamic> json) {
    final available = json['available'] as bool? ?? false;
    return VehicleTypeQuoteModel(
      vehicleTypeId: json['vehicle_type_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      available: available,
      price: available
          ? ((json['estimated_price'] ?? json['price']) as num?)?.toDouble()
          : null,
      stopsFeeTotal: (json['stops_fee_total'] as num?)?.toDouble() ?? 0,
      locationFee: available ? (json['location_fee'] as num?)?.toDouble() ?? 0 : 0,
    );
  }

  @override
  List<Object?> get props => [
    vehicleTypeId,
    name,
    description,
    available,
    price,
    stopsFeeTotal,
    locationFee,
  ];
}
