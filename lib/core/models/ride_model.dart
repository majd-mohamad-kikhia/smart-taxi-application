import 'package:equatable/equatable.dart';
import 'cancel_penalty_model.dart';

/// A ride order as returned by `POST /api/customer/rides/choose-vehicle`
/// and `POST /api/customer/rides/{id}/cancel`.
///
/// [price] is an *estimate* based on straight-line distance — swagger is
/// explicit that the final fare can differ if the driver takes another
/// route (see [priceIsEstimate]).
///
/// Lives in `core` (not `features/home`, which created it) because the
/// ride-tracking feature also needs it once the order moves past
/// `choose-vehicle` — see the "move to core" rule for cross-feature types.
class RideModel extends Equatable {
  static const int scheduledStatusId = 7;

  final int id;
  final int vehicleTypeId;
  final double? distanceKm;
  final double? price;
  final bool priceIsEstimate;
  final int statusId;
  final String status;

  /// Pickup time of a scheduled ride, UTC `YYYY-MM-DD HH:MM:SS`; null for
  /// an immediate ride.
  final String? scheduledAt;

  /// Set on a cancel that counted against the customer (a driver had
  /// accepted).
  final CancelPenaltyModel? cancelPenalty;

  const RideModel({
    required this.id,
    required this.vehicleTypeId,
    this.distanceKm,
    this.price,
    required this.priceIsEstimate,
    required this.statusId,
    required this.status,
    this.scheduledAt,
    this.cancelPenalty,
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
      scheduledAt: json['scheduled_at'] as String?,
      cancelPenalty: CancelPenaltyModel.fromRide(json),
    );
  }

  /// Waiting for its time; nothing is offered to drivers yet.
  bool get isScheduled => statusId == scheduledStatusId;

  @override
  List<Object?> get props => [
        id,
        vehicleTypeId,
        distanceKm,
        price,
        priceIsEstimate,
        statusId,
        status,
        scheduledAt,
        cancelPenalty,
      ];
}
