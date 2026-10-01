import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';

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

  /// Waiting at pickup — null until the driver taps "arrived".
  final RideWaitingModel? waiting;

  /// The waiting fee; final once the trip has started, 0 before.
  final double waitingFee;

  /// Pauses during the trip (the driver stopped for a coffee, …). Null
  /// until the server sends one.
  final RidePauseModel? pause;

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
    this.waiting,
    this.waitingFee = 0,
    this.pause,
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
      waiting: RideWaitingModel.fromParent(json),
      waitingFee: (json['waiting_fee'] as num?)?.toDouble() ?? 0,
      pause: RidePauseModel.fromParent(json),
    );
  }

  /// Applies a `customer:ride_status` event. Status events don't carry the
  /// whole ride, so [waiting] / [waitingFee] are only replaced when the
  /// event includes them.
  TrackedRideModel copyWithStatus({
    required int statusId,
    required String status,
    RideWaitingModel? waiting,
    double? waitingFee,
    RidePauseModel? pause,
  }) {
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
      waiting: waiting ?? this.waiting,
      waitingFee: waitingFee ?? this.waitingFee,
      pause: pause ?? this.pause,
    );
  }

  /// Applies a `customer:ride_pause_update`: the trip was paused or
  /// resumed. The status stays `in_progress` either way.
  TrackedRideModel copyWithPause(RidePauseModel pause) {
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
      waiting: waiting,
      waitingFee: waitingFee,
      pause: pause,
    );
  }

  /// The waiting timer should be counting on screen.
  bool get isWaitingRunning => status == 'arrived' && (waiting?.isRunning ?? false);

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
        waiting,
        waitingFee,
        pause,
      ];
}
