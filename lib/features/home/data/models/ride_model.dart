import 'package:equatable/equatable.dart';

/// A ride order as returned by `POST /api/customer/rides/choose-vehicle`
/// and `POST /api/customer/rides/{id}/cancel`.
///
/// [price] is an *estimate* based on straight-line distance — swagger is
/// explicit that the final fare can differ if the driver takes another
/// route (see [priceIsEstimate]).
class RideModel extends Equatable {
  final int id;
  final int vehicleTypeId;
  final double? distanceKm;
  final double? price;
  final bool priceIsEstimate;
  final int statusId;
  final String status;

  const RideModel({
    required this.id,
    required this.vehicleTypeId,
    this.distanceKm,
    this.price,
    required this.priceIsEstimate,
    required this.statusId,
    required this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicle_type_id'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble() ??
          (json['estimated_price'] as num?)?.toDouble(),
      priceIsEstimate: json['price_is_estimate'] as bool? ?? false,
      statusId: json['status_id'] as int,
      status: json['status'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleTypeId,
        distanceKm,
        price,
        priceIsEstimate,
        statusId,
        status,
      ];
}
