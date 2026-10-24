import 'package:equatable/equatable.dart';
import 'ride_booking_options_model.dart';

/// An order waiting for the customer to accept a different final fare: the
/// route fare came out more than 15 % away from the one they saw. Accepting
/// creates the ride with the same [idempotencyKey], so the quoted fare is the
/// one charged.
class PendingBookingModel extends Equatable {
  final RideBookingOptionsModel options;
  final String idempotencyKey;

  /// The server's final fare, shown as it came.
  final double fare;

  const PendingBookingModel({
    required this.options,
    required this.idempotencyKey,
    required this.fare,
  });

  @override
  List<Object?> get props => [options, idempotencyKey, fare];
}
