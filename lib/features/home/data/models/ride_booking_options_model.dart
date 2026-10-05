import 'package:equatable/equatable.dart';

/// What the customer chose on the vehicle sheet: the vehicle type and an
/// optional note for the driver.
class RideBookingOptionsModel extends Equatable {
  final int vehicleTypeId;
  final String? note;

  const RideBookingOptionsModel({
    required this.vehicleTypeId,
    this.note,
  });

  @override
  List<Object?> get props => [vehicleTypeId, note];
}
