import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/models/trip_eta_model.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_location_model.dart';
import '../../data/models/ride_vehicle_model.dart';
import '../../data/models/tracked_ride_model.dart';

enum RideTrackingConnectionStatus { connecting, connected, error }

/// Why the tracking screen is allowed to close — it otherwise blocks the
/// back gesture/button (see `RideTrackingScreen`).
enum RideTrackingExitReason { completed, cancelledByServer, cancelledByUser }

/// Which stretch of road the map line and the arrival time describe.
enum RideRouteLeg {
  /// Nothing to show: no driver yet, the driver is already at the pickup, or
  /// the trip is over.
  none,

  /// The driver heading to the pickup.
  toPickup,

  /// The trip itself, pickup to dropoff.
  toDropoff,
}

class RideTrackingState extends Equatable {
  final RideTrackingConnectionStatus connectionStatus;
  final String? connectionError;
  final TrackedRideModel ride;
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;
  final RideDriverModel? driver;
  final RideVehicleModel? vehicle;
  final RideLocationModel? driverLocation;

  /// The road line on the map: the driver's way to the pickup (following
  /// the driver), then the planned route pickup to dropoff (fixed for the
  /// whole trip). See [routeLeg].
  final List<RoutePointModel> routePoints;

  /// The planned road from pickup to dropoff (Google Routes), drawn instead
  /// of a straight line while the customer waits for the driver. Empty until
  /// it has loaded.
  final List<RoutePointModel> plannedRoute;

  /// Remaining road distance and travel time of [routeLeg]; null until the
  /// first route has loaded.
  final TripEtaModel? eta;

  /// The path the driver's car has been seen driving since the ride started.
  final List<RoutePointModel> drivenPath;

  /// The server's final price, from the `completed` status event.
  final double? finalPrice;

  /// The bill lines (distance, stops, waiting…) from the `completed` event.
  final RideFareBreakdownModel? fare;
  final bool isCancelling;

  /// The `completed` event said the customer can rate this driver
  /// (`can_rate`): the rating dialog follows the payment.
  final bool canRate;

  /// The server's message when the last cancel attempt failed; the screen
  /// shows it once and the customer can retry.
  final String? cancelError;
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
    this.eta,
    this.plannedRoute = const [],
    this.drivenPath = const [],
    this.finalPrice,
    this.fare,
    required this.isCancelling,
    this.canRate = false,
    this.cancelError,
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

  /// What the road line and the arrival time currently measure.
  RideRouteLeg get routeLeg {
    if (isInProgress) return RideRouteLeg.toDropoff;
    if (ride.status == 'accepted' && isAccepted) return RideRouteLeg.toPickup;
    return RideRouteLeg.none;
  }

  RideTrackingState copyWith({
    RideTrackingConnectionStatus? connectionStatus,
    String? connectionError,
    bool clearConnectionError = false,
    TrackedRideModel? ride,
    RideDriverModel? driver,
    RideVehicleModel? vehicle,
    RideLocationModel? driverLocation,
    List<RoutePointModel>? routePoints,
    TripEtaModel? eta,
    List<RoutePointModel>? plannedRoute,
    bool clearRoute = false,
    bool clearEta = false,
    List<RoutePointModel>? drivenPath,
    double? finalPrice,
    RideFareBreakdownModel? fare,
    bool? isCancelling,
    bool? canRate,
    String? cancelError,
    bool clearCancelError = false,
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
      routePoints: clearRoute ? const [] : (routePoints ?? this.routePoints),
      eta: clearEta ? null : (eta ?? this.eta),
      plannedRoute: plannedRoute ?? this.plannedRoute,
      drivenPath: drivenPath ?? this.drivenPath,
      finalPrice: finalPrice ?? this.finalPrice,
      fare: fare ?? this.fare,
      isCancelling: isCancelling ?? this.isCancelling,
      canRate: canRate ?? this.canRate,
      cancelError: clearCancelError ? null : (cancelError ?? this.cancelError),
      exitReason: exitReason ?? this.exitReason,
    );
  }

  @override
  List<Object?> get props => [
        canRate,
        connectionStatus,
        connectionError,
        ride,
        pickup,
        dropoff,
        driver,
        vehicle,
        driverLocation,
        routePoints,
        eta,
        plannedRoute,
        drivenPath,
        finalPrice,
        fare,
        isCancelling,
        cancelError,
        exitReason,
      ];
}
