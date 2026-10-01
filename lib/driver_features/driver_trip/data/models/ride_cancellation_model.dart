import 'package:equatable/equatable.dart';

/// Who cancelled the ride, as reported in `cancelled_by`.
enum RideCancelledBy {
  customer,
  manager,
  driver;

  static RideCancelledBy? parse(Object? value) => switch (value) {
    'customer' => customer,
    'manager' => manager,
    'driver' => driver,
    _ => null,
  };
}

/// The `driver:ride_cancelled` socket event. The FCM push for a customer
/// cancel carries the same fields, but as strings (`ride_id: "42"`), so
/// [fromJson] reads the id leniently. Returns null when there is no usable
/// `ride_id`.
class RideCancellationModel extends Equatable {
  final int rideId;
  final RideCancelledBy? cancelledBy;
  final String? reason;

  const RideCancellationModel({
    required this.rideId,
    this.cancelledBy,
    this.reason,
  });

  static RideCancellationModel? fromJson(Map<String, dynamic> json) {
    final rideId = int.tryParse('${json['ride_id'] ?? json['related_ride_id']}');
    if (rideId == null) return null;
    final reason = json['cancellation_reason'] as String?;
    return RideCancellationModel(
      rideId: rideId,
      cancelledBy: RideCancelledBy.parse(json['cancelled_by']),
      reason: reason == null || reason.isEmpty ? null : reason,
    );
  }

  @override
  List<Object?> get props => [rideId, cancelledBy, reason];
}
