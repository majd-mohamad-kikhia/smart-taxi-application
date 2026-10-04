import 'package:equatable/equatable.dart';

/// What the customer chose on the vehicle sheet: the vehicle type, an
/// optional note for the driver and, for a scheduled ride, its time.
class RideBookingOptionsModel extends Equatable {
  final int vehicleTypeId;
  final String? note;

  /// Null for a ride now.
  final DateTime? scheduledAt;

  const RideBookingOptionsModel({
    required this.vehicleTypeId,
    this.note,
    this.scheduledAt,
  });

  @override
  List<Object?> get props => [vehicleTypeId, note, scheduledAt];
}
