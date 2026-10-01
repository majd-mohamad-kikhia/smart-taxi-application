import 'package:equatable/equatable.dart';
import '../../data/models/driver_active_ride_model.dart';

/// Result of asking the server whether the driver still has a ride to
/// resume. [ride] is set only once, when there is one to go back to.
class DriverActiveRideState extends Equatable {
  final DriverActiveRideModel? ride;

  const DriverActiveRideState({this.ride});

  @override
  List<Object?> get props => [ride];
}
