import 'package:equatable/equatable.dart';
import '../../data/models/driver_active_ride_model.dart';

/// A ride the shell should open the trip screen for: one left over from
/// before the app closed, or one the office just assigned to the driver.
/// [version] grows with every ride to open, so the same ride can be opened
/// again after its screen was closed.
class DriverActiveRideState extends Equatable {
  final DriverActiveRideModel? ride;

  /// The ride was sent over `driver:active_ride` rather than found at
  /// startup — usually an office assignment.
  final bool isAssigned;
  final int version;

  const DriverActiveRideState({
    this.ride,
    this.isAssigned = false,
    this.version = 0,
  });

  @override
  List<Object?> get props => [ride, isAssigned, version];
}
