import 'package:equatable/equatable.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
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

  /// Current waiting-at-pickup rules, so the order screen can show them.
  /// Null when the server didn't send `waiting_fee`.
  final WaitingFeeRulesModel? waitingFee;

  /// Current rules for stopping during the trip; null when not sent.
  final PauseFeeRulesModel? pauseFee;

  /// The listed area that carries a location fee (`location_fee.name`), to
  /// tell the customer which one; null when the trip touches none. The fee
  /// itself is per car (see `VehicleTypeQuoteModel.locationFee`) — the
  /// top-level `fee` is only for old apps and is not read.
  final String? locationFeeName;

  const RideQuoteModel({
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.vehicleTypes,
    this.waitingFee,
    this.pauseFee,
    this.locationFeeName,
  });

  factory RideQuoteModel.fromJson(Map<String, dynamic> json) {
    final types = json['vehicle_types'] as List? ?? [];
    final rules = json['waiting_fee'];
    final pauseRules = json['pause_fee'];
    final area = json['location_fee'];
    final areaName = area is Map ? area['name'] : null;
    return RideQuoteModel(
      locationFeeName: areaName is String && areaName.trim().isNotEmpty ? areaName.trim() : null,
      pauseFee: pauseRules is Map
          ? PauseFeeRulesModel.fromJson(Map<String, dynamic>.from(pauseRules))
          : null,
      waitingFee: rules is Map
          ? WaitingFeeRulesModel.fromJson(Map<String, dynamic>.from(rules))
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      estimatedDurationMin: json['estimated_duration_min'] as int? ?? 0,
      vehicleTypes: types
          .map((t) => VehicleTypeQuoteModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [distanceKm, estimatedDurationMin, vehicleTypes, waitingFee, pauseFee, locationFeeName];
}
