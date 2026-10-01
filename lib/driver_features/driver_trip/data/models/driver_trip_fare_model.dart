import 'package:equatable/equatable.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';

/// The server's final fare for a finished ride — the `ride.fare` object
/// returned by `POST /api/driver/rides/{id}/finish` (or the
/// `driver:ride_finish` ack):
/// `final_price = base_fare + distance_fare + stops_fee_total + waiting_fee`.
class DriverTripFareModel extends Equatable {
  final double finalPrice;
  final double estimatedPrice;
  final double difference;
  final double actualDistanceKm;
  final double commissionRate;
  final double adminCommissionAmount;
  final double driverEarningAmount;

  /// The bill lines (distance, stops, waiting…). The commission is taken
  /// from the total, waiting fee included.
  final RideFareBreakdownModel breakdown;

  const DriverTripFareModel({
    required this.finalPrice,
    required this.estimatedPrice,
    required this.difference,
    required this.actualDistanceKm,
    required this.commissionRate,
    required this.adminCommissionAmount,
    required this.driverEarningAmount,
    required this.breakdown,
  });

  /// Parses the finished ride. Uses `ride['fare']` when the server sends
  /// it, and falls back to the ride's own `price` (which becomes the
  /// final price on finish) so the driver still sees the amount.
  factory DriverTripFareModel.fromRideJson(Map<String, dynamic> ride) {
    final fare = ride['fare'] is Map
        ? Map<String, dynamic>.from(ride['fare'] as Map)
        : ride;
    double number(String key, [String? fallbackKey]) =>
        (fare[key] as num? ?? ride[fallbackKey ?? key] as num? ?? 0).toDouble();

    final finalPrice = number('final_price', 'price');
    final estimatedPrice = number('estimated_price');
    return DriverTripFareModel(
      finalPrice: finalPrice,
      estimatedPrice: estimatedPrice,
      difference: (fare['difference'] as num?)?.toDouble() ?? finalPrice - estimatedPrice,
      actualDistanceKm: number('actual_distance_km', 'distance_km'),
      commissionRate: number('commission_rate', 'commission_rate_applied'),
      adminCommissionAmount: number('admin_commission_amount'),
      driverEarningAmount: number('driver_earning_amount'),
      breakdown: RideFareBreakdownModel.fromJson(
        Map<String, dynamic>.from(fare),
        fallbackFinalPrice: finalPrice,
      ),
    );
  }

  @override
  List<Object?> get props => [
    finalPrice,
    estimatedPrice,
    difference,
    actualDistanceKm,
    commissionRate,
    adminCommissionAmount,
    driverEarningAmount,
    breakdown,
  ];
}
