import 'package:equatable/equatable.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';

/// What goes on the bill of a finished, paid ride sent to its customer.
class RideBillModel extends Equatable {
  final int rideId;

  /// When the trip ended, in the phone's time zone.
  final DateTime issuedAt;
  final String? customerName;
  final String? customerPhone;
  final String? driverName;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;

  /// The bill lines; `breakdown.finalPrice` is the total.
  final RideFareBreakdownModel breakdown;

  const RideBillModel({
    required this.rideId,
    required this.issuedAt,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.breakdown,
    this.customerName,
    this.customerPhone,
    this.driverName,
  });

  String get fileName => 'smart_taxi_bill_$rideId.pdf';

  @override
  List<Object?> get props => [
    rideId,
    issuedAt,
    customerName,
    customerPhone,
    driverName,
    pickupAddress,
    dropoffAddress,
    distanceKm,
    breakdown,
  ];
}
