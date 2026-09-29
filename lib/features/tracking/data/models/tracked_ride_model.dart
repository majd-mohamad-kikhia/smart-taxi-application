import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/models/ride_model.dart';

/// The `ride` object as pushed by `customer:ride_accepted` /
/// `customer:active_ride` / `customer:ride_status` (see docs/socket.md).
/// Seeded from the [RideModel] returned by `choose-vehicle` while the
/// customer is still waiting for a driver, then replaced/updated by the
/// authoritative socket payloads once a driver accepts.
class TrackedRideModel extends Equatable {
  final int id;
  final int? driverId;
  final int vehicleTypeId;
  final double? distanceKm;
  final int? estimatedDurationMin;
  final double? price;
  final bool priceIsEstimate;
  final int statusId;
  final String status;

  const TrackedRideModel({
    required this.id,
    this.driverId,
    required this.vehicleTypeId,
    this.distanceKm,
    this.estimatedDurationMin,
    this.price,
    required this.priceIsEstimate,
    required this.statusId,
    required this.status,
  });

  factory TrackedRideModel.fromRideModel(RideModel ride) {
    return TrackedRideModel(
      id: ride.id,
      vehicleTypeId: ride.vehicleTypeId,
      distanceKm: ride.distanceKm,
      price: ride.price,
      priceIsEstimate: ride.priceIsEstimate,
      statusId: ride.statusId,
      status: ride.status,
    );
  }

  factory TrackedRideModel.fromJson(Map<String, dynamic> json) {
    return TrackedRideModel(
      id: (json['id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      vehicleTypeId: (json['vehicle_type_id'] as num).toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: (json['estimated_duration_min'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      priceIsEstimate: json['price_is_estimate'] as bool? ?? true,
      statusId: (json['status_id'] as num).toInt(),
      status: json['status'] as String,
    );
  }

  TrackedRideModel copyWithStatus({required int statusId, required String status}) {
    return TrackedRideModel(
      id: id,
      driverId: driverId,
      vehicleTypeId: vehicleTypeId,
      distanceKm: distanceKm,
      estimatedDurationMin: estimatedDurationMin,
      price: price,
      priceIsEstimate: priceIsEstimate,
      statusId: statusId,
      status: status,
    );
  }

  String statusLabel(AppLocalizations l10n) => switch (status) {
        'requested' => l10n.rideAwaitingDriver,
        'accepted' => l10n.trackDriverOnTheWay,
        'arrived' => l10n.trackDriverAtPickup,
        'in_progress' => l10n.rideInProgress,
        'completed' => l10n.rideCompleted,
        'cancelled' => l10n.tripCancelled,
        _ => status,
      };

  @override
  List<Object?> get props => [
        id,
        driverId,
        vehicleTypeId,
        distanceKm,
        estimatedDurationMin,
        price,
        priceIsEstimate,
        statusId,
        status,
      ];
}
