import 'package:equatable/equatable.dart';
import '../../../../core/utils/parse_utc_date.dart';
import 'driver_trip_customer_model.dart';
import 'driver_trip_fare_model.dart';
import 'ride_order_source.dart';

/// `POST /api/driver/rides/{id}/finish`: the final fare, plus what the bill
/// of an office order needs (who ordered, how, and when the trip ended).
class DriverRideFinishModel extends Equatable {
  final DriverTripFareModel fare;
  final RideOrderSource orderSource;
  final DriverTripCustomerModel? customer;

  /// UTC.
  final DateTime? completedAt;

  const DriverRideFinishModel({
    required this.fare,
    this.orderSource = RideOrderSource.app,
    this.customer,
    this.completedAt,
  });

  factory DriverRideFinishModel.fromRideJson(Map<String, dynamic> ride) {
    final completedAt = ride['completed_at'];
    return DriverRideFinishModel(
      fare: DriverTripFareModel.fromRideJson(ride),
      orderSource: RideOrderSource.fromWire(ride['order_source']),
      customer: DriverTripCustomerModel.fromParent(ride),
      completedAt: completedAt is String ? parseUtcDateTime(completedAt) : null,
    );
  }

  @override
  List<Object?> get props => [fare, orderSource, customer, completedAt];
}
