import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_location_model.dart';
import '../../data/models/ride_vehicle_model.dart';
import '../../data/models/tracked_ride_model.dart';

enum RideTrackingConnectionStatus { connecting, connected, error }

/// Why the tracking screen is allowed to close — it otherwise blocks the
/// back gesture/button (see `RideTrackingScreen`).
enum RideTrackingExitReason { completed, cancelledByServer, cancelledByUser }

class RideTrackingState extends Equatable {
  final RideTrackingConnectionStatus connectionStatus;
  final String? connectionError;
  final TrackedRideModel ride;
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;
  final RideDriverModel? driver;
  final RideVehicleModel? vehicle;
  final RideLocationModel? driverLocation;

  /// Planned road route, pickup to dropoff — fixed for the whole trip.
  final List<RoutePointModel> routePoints;

  /// The path the driver's car has been seen driving since the ride started.
  final List<RoutePointModel> drivenPath;

  /// The server's final price, from the `completed` status event.
  final double? finalPrice;
  final bool isCancelling;
  final RideTrackingExitReason? exitReason;

  const RideTrackingState({
    required this.connectionStatus,
    this.connectionError,
    required this.ride,
    required this.pickup,
    required this.dropoff,
    this.driver,
    this.vehicle,
    this.driverLocation,
    this.routePoints = const [],
    this.drivenPath = const [],
    this.finalPrice,
    required this.isCancelling,
    this.exitReason,
  });

  factory RideTrackingState.initial({
    required TrackedRideModel ride,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) {
    return RideTrackingState(
      connectionStatus: RideTrackingConnectionStatus.connecting,
      ride: ride,
      pickup: pickup,
      dropoff: dropoff,
      isCancelling: false,
    );
  }

  /// A driver has accepted — the "waiting for driver" UI gives way to the
  /// driver/vehicle card + live pin.
  bool get isAccepted => driver != null;

  /// The driver has started the ride — the screen shows only the live map.
  bool get isInProgress => ride.status == 'in_progress';

  /// The driver finished the trip and hasn't confirmed the cash payment
  /// yet — the customer has to pay before the screen can close.
  bool get isAwaitingPayment => ride.status == 'completed' && exitReason == null;

  /// Only the live map is shown: while driving, and while paying at the end.
  bool get showsLiveMap => isInProgress || isAwaitingPayment;

  RideTrackingState copyWith({
    RideTrackingConnectionStatus? connectionStatus,
    String? connectionError,
    bool clearConnectionError = false,
    TrackedRideModel? ride,
    RideDriverModel? driver,
    RideVehicleModel? vehicle,
    RideLocationModel? driverLocation,
    List<RoutePointModel>? routePoints,
    List<RoutePointModel>? drivenPath,
    double? finalPrice,
    bool? isCancelling,
    RideTrackingExitReason? exitReason,
  }) {
    return RideTrackingState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionError:
          clearConnectionError ? null : (connectionError ?? this.connectionError),
      ride: ride ?? this.ride,
      pickup: pickup,
      dropoff: dropoff,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      driverLocation: driverLocation ?? this.driverLocation,
      routePoints: routePoints ?? this.routePoints,
      drivenPath: drivenPath ?? this.drivenPath,
      finalPrice: finalPrice ?? this.finalPrice,
      isCancelling: isCancelling ?? this.isCancelling,
      exitReason: exitReason ?? this.exitReason,
    );
  }

  @override
  List<Object?> get props => [
        connectionStatus,
        connectionError,
        ride,
        pickup,
        dropoff,
        driver,
        vehicle,
        driverLocation,
        routePoints,
        drivenPath,
        finalPrice,
        isCancelling,
        exitReason,
      ];
}
