import 'package:equatable/equatable.dart';
import 'vehicle_type_quote_model.dart';

/// Result of `POST /api/customer/rides/locations` (order flow step 1):
/// the validated pickup/dropoff, the server-computed distance/ETA, and a
/// price quote per active vehicle type. Creates nothing — the customer
/// picks a `vehicle_type_id` from [vehicleTypes] to actually request the
/// ride.
class RideQuoteModel extends Equatable {
  final double distanceKm;
  final int estimatedDurationMin;
  final List<VehicleTypeQuoteModel> vehicleTypes;

  const RideQuoteModel({
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.vehicleTypes,
  });

  factory RideQuoteModel.fromJson(Map<String, dynamic> json) {
    final types = json['vehicle_types'] as List? ?? [];
    return RideQuoteModel(
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      estimatedDurationMin: json['estimated_duration_min'] as int? ?? 0,
      vehicleTypes: types
          .map((t) => VehicleTypeQuoteModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [distanceKm, estimatedDurationMin, vehicleTypes];
}
