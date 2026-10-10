import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/account_block/account_block_cubit.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/cancel_penalty_model.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_fare_breakdown_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/models/trip_eta_model.dart';
import '../../../../core/services/trip_route_tracker.dart';
import '../../data/datasources/customer_ride_socket_service.dart';
import '../../data/models/ride_driver_model.dart';
import '../../data/models/ride_location_model.dart';
import '../../data/models/ride_vehicle_model.dart';
import '../../../../core/services/google_routes_service.dart';
import '../../data/models/tracked_ride_model.dart';
import 'ride_tracking_state.dart';

/// Bundled constructor args for `sl<RideTrackingCubit>(param1: ...)` — a
/// record instead of `registerFactoryParam`'s two slots, since three
/// values are needed.
typedef RideTrackingCubitArgs = ({
  RideModel initialRide,
  PickedLocationModel pickup,
  PickedLocationModel dropoff,
});

/// Drives the ride-tracking screen: connects a dedicated
/// [CustomerRideSocketService] for this one ride, applies
/// `customer:ride_accepted` / `customer:active_ride` / `driver_location` /
/// `ride_status` events (see docs/socket.md), keeps the road line and the
/// arrival time of the current leg up to date (see [RideTrackingState.routeLeg]),
/// and exposes the cancel-with-reason flow.
class RideTrackingCubit extends Cubit<RideTrackingState> {
  /// `cancellation_reason` is capped at 255 characters by the server.
  static const int _maxCancellationReasonLength = 255;

  /// How long the screen stays open for our own cancel's answer once the
  /// ride already shows cancelled.
  static const Duration _cancelAnswerWait = Duration(seconds: 6);

  final CustomerRideSocketService _socketService;
  final TripRouteTracker _routeTracker;
  final AccountBlockCubit _accountBlock;
  final GoogleRoutesService? _plannedRoutes;
  Timer? _cancelAnswerTimer;
  RideRouteLeg _trackedLeg = RideRouteLeg.none;

  RideTrackingCubit(
    this._socketService,
    this._routeTracker,
    this._accountBlock, {
    required RideModel initialRide,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
    GoogleRoutesService? plannedRoutes,
  }) : _plannedRoutes = plannedRoutes,
       super(RideTrackingState.initial(
          ride: TrackedRideModel.fromRideModel(initialRide),
          pickup: pickup,
          dropoff: dropoff,
        ));

  /// Loads the road from pickup to dropoff once (Google Routes), so the map
  /// shows the real way instead of a straight line from the first moment.
  Future<void> _loadPlannedRoute() async {
    final service = _plannedRoutes;
    if (service == null) return;
    final from = state.pickup, to = state.dropoff;
    try {
      final route = await service.computeRoute(
        fromLat: from.latitude,
        fromLng: from.longitude,
        toLat: to.latitude,
        toLng: to.longitude,
      );
      if (!isClosed && route.points.length >= 2) {
        emit(state.copyWith(plannedRoute: route.points));
        return;
      }
    } catch (e) {
      debugPrint('RideTrackingCubit: Google route failed: $e');
    }
  }

  void connect() {
    unawaited(_loadPlannedRoute());
    final token = ApiClient.authToken;
    if (token == null) {
      emit(state.copyWith(
        connectionStatus: RideTrackingConnectionStatus.error,
        connectionError: AppStrings.current.errLoginRequired,
      ));
      return;
    }

    _socketService.connect(
      accessToken: token,
      onConnect: () {
        if (!isClosed) {
          emit(state.copyWith(
            connectionStatus: RideTrackingConnectionStatus.connected,
            clearConnectionError: true,
          ));
        }
      },
      onDisconnect: () {
        if (!isClosed) {
          emit(state.copyWith(connectionStatus: RideTrackingConnectionStatus.connecting));
        }
      },
      onConnectError: (_) {
        if (!isClosed) {
          emit(state.copyWith(
            connectionStatus: RideTrackingConnectionStatus.error,
            connectionError: AppStrings.current.errServerUnreachable,
          ));
        }
      },
      onRideAccepted: _applySnapshot,
      onDriverLocation: _handleDriverLocation,
      onRideStatus: _handleRideStatus,
      onRidePauseUpdate: _handlePauseUpdate,
      onRidePaid: _handleRidePaid,
      onActiveRide: (data) {
        if (data != null) _applySnapshot(data);
      },
    );
  }

  // Socket.io's EventEmitter (socket_io_common) invokes listeners with no
  // try/catch, so an exception anywhere in here would silently kill this
  // one event's processing (no crash, no log) while other events on the
  // same socket — e.g. `driver_location` — keep working fine. Each field
  // is parsed defensively so a malformed/missing `driver` or `vehicle`
  // can't block the (more important) ride-status update.
  void _applySnapshot(Map<String, dynamic> data) {
    try {
      final rideJson = data['ride'] as Map?;
      if (rideJson == null) return;
      var ride = TrackedRideModel.fromJson(Map<String, dynamic>.from(rideJson));
      if (ride.id != state.ride.id) return;
      // A snapshot that names the driver means the order was accepted, even
      // when its `status` still says `requested` (or the status event was
      // missed): never show "waiting for acceptance" beside a driver.
      if (data['driver'] is Map && ride.status == 'requested') {
        ride = ride.copyWithStatus(statusId: 2, status: 'accepted');
      }

      final driverJson = data['driver'] as Map?;
      final vehicleJson = data['vehicle'] as Map?;
      final locationJson = data['location'] as Map?;

      RideDriverModel? driver = state.driver;
      if (driverJson != null) {
        try {
          driver = RideDriverModel.fromJson(Map<String, dynamic>.from(driverJson));
        } catch (e) {
          debugPrint('RideTrackingCubit: failed to parse driver payload: $e');
        }
      }

      RideVehicleModel? vehicle = state.vehicle;
      if (vehicleJson != null) {
        try {
          vehicle = RideVehicleModel.fromJson(Map<String, dynamic>.from(vehicleJson));
        } catch (e) {
          debugPrint('RideTrackingCubit: failed to parse vehicle payload: $e');
        }
      }

      final location = locationJson != null
          ? RideLocationModel.fromJson(Map<String, dynamic>.from(locationJson))
          : state.driverLocation;

      if (!isClosed) {
        emit(state.copyWith(ride: ride, driver: driver, vehicle: vehicle, driverLocation: location));
        unawaited(_updateRoute());
      }
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to apply ride snapshot: $e');
    }
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    try {
      if ((data['ride_id'] as num).toInt() != state.ride.id) return;
      if (isClosed) return;
      final location = RideLocationModel.fromJson(data);
      if (state.isInProgress) {
        emit(state.copyWith(
          driverLocation: location,
          drivenPath: [...state.drivenPath, RoutePointModel(location.lat, location.lng)],
        ));
      } else {
        emit(state.copyWith(driverLocation: location));
      }
      unawaited(_updateRoute());
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to apply driver location: $e');
    }
  }

  void _handleRideStatus(Map<String, dynamic> data) {
    try {
      if ((data['ride_id'] as num).toInt() != state.ride.id) return;
      if (isClosed) return;

      final updatedRide = state.ride.copyWithStatus(
        statusId: (data['status_id'] as num).toInt(),
        status: data['status'] as String,
        // `arrived` starts the timer; `in_progress` stops it and carries the
        // final fee. The server's numbers replace any local count.
        waiting: RideWaitingModel.fromParent(data),
        waitingFee: (data['waiting_fee'] as num?)?.toDouble(),
      );

      if (updatedRide.status == 'completed') {
        // Not an exit yet: the customer still has to pay the driver, and the
        // screen closes on `customer:ride_paid` (see [_handleRidePaid]).
        final finalPrice = (data['final_price'] as num?)?.toDouble() ?? updatedRide.price ?? 0;
        emit(state.copyWith(
          ride: updatedRide,
          finalPrice: finalPrice,
          canRate: data['can_rate'] == true,
          fare: RideFareBreakdownModel.fromParent(data, fallbackFinalPrice: finalPrice),
        ));
        unawaited(_updateRoute());
      } else if (updatedRide.status == 'cancelled') {
        if (state.isCancelling) {
          // Our own cancel: closing now would drop the socket before its
          // answer, which carries the cancel penalty.
          emit(state.copyWith(ride: updatedRide));
          _cancelAnswerTimer ??= Timer(_cancelAnswerWait, _exitWithoutCancelAnswer);
          return;
        }
        emit(state.copyWith(
          ride: updatedRide,
          exitReason: state.exitReason ?? RideTrackingExitReason.cancelledByServer,
        ));
      } else {
        emit(state.copyWith(ride: updatedRide));
        unawaited(_updateRoute());
      }
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to apply ride status: $e');
    }
  }

  /// The driver paused or resumed the trip (`customer:ride_pause_update`).
  /// The server's numbers replace any local count; the status stays
  /// `in_progress`.
  void _handlePauseUpdate(Map<String, dynamic> data) {
    try {
      if ((data['ride_id'] as num).toInt() != state.ride.id) return;
      final pause = RidePauseModel.fromParent(data);
      if (isClosed || pause == null) return;
      emit(state.copyWith(ride: state.ride.copyWithPause(pause)));
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to apply pause update: $e');
    }
  }

  /// The driver confirmed the cash payment — the trip is fully done.
  void _handleRidePaid(Map<String, dynamic> data) {
    try {
      final rideId = (data['ride_id'] as num?)?.toInt();
      if (rideId != null && rideId != state.ride.id) return;
      if (!isClosed) emit(state.copyWith(exitReason: RideTrackingExitReason.completed));
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to apply ride paid: $e');
    }
  }

  /// Keeps the map's road line and the arrival time in step with the
  /// current leg: the driver's way to the pickup, then the trip to the
  /// dropoff. Cheap to call on every GPS fix — the tracker only asks the
  /// routing service when it has to, and the state only changes when the
  /// line or the displayed time does.
  Future<void> _updateRoute() async {
    try {
      final leg = state.routeLeg;
      if (leg != _trackedLeg) {
        final previous = _trackedLeg;
        _trackedLeg = leg;
        _routeTracker.reset();
        // The time of the old leg is wrong for the new one. The way to the
        // pickup means nothing once the driver is there; the trip's own
        // route stays on the map until the screen closes.
        emit(state.copyWith(clearEta: true, clearRoute: previous == RideRouteLeg.toPickup));
      }
      if (leg == RideRouteLeg.none) return;

      final isTrip = leg == RideRouteLeg.toDropoff;
      final target = isTrip ? state.dropoff : state.pickup;
      // A trip that just started has no fix yet: it starts at the pickup.
      final carLat = state.driverLocation?.lat ?? (isTrip ? state.pickup.latitude : null);
      final carLng = state.driverLocation?.lng ?? (isTrip ? state.pickup.longitude : null);
      if (carLat == null || carLng == null) return;

      final snapshot = await _routeTracker.update(
        carLat: carLat,
        carLng: carLng,
        targetLat: target.latitude,
        targetLng: target.longitude,
        keepLine: isTrip,
      );
      if (isClosed || leg != state.routeLeg) return;

      final progress = snapshot.progress;
      emit(state.copyWith(
        routePoints: snapshot.line.isEmpty ? null : snapshot.line,
        eta: progress == null
            ? null
            : TripEtaModel.fromRemaining(
                meters: progress.remainingMeters,
                seconds: progress.remainingSeconds,
              ),
      ));
    } catch (e) {
      debugPrint('RideTrackingCubit: failed to update the route: $e');
    }
  }

  /// Cancels the ride over the socket (`customer:ride_cancel`). On success
  /// the screen closes and a counted cancel (a driver had accepted) goes to
  /// [AccountBlockCubit], which shows the server's warning or block. On
  /// failure [RideTrackingState.cancelError] carries the server's message
  /// and the customer can retry.
  void submitCancellation(String reason) {
    if (isClosed || state.isCancelling) return;
    emit(state.copyWith(isCancelling: true, clearCancelError: true));
    _socketService.cancelRide(
      rideId: state.ride.id,
      cancellationReason: reason.length > _maxCancellationReasonLength
          ? reason.substring(0, _maxCancellationReasonLength)
          : reason,
      onResult: (ok, error, ride) {
        if (isClosed) return;
        _cancelAnswerTimer?.cancel();
        _cancelAnswerTimer = null;
        if (!ok && state.ride.status != 'cancelled') {
          emit(state.copyWith(
            isCancelling: false,
            cancelError: error ?? AppStrings.current.errUnexpected,
          ));
          return;
        }
        // The screen closes first, so the penalty dialog opens above home.
        emit(state.copyWith(
          isCancelling: false,
          exitReason: state.exitReason ?? RideTrackingExitReason.cancelledByUser,
        ));
        final penalty = CancelPenaltyModel.fromRide(ride);
        if (penalty != null) _accountBlock.applyCancelPenalty(penalty);
      },
    );
  }

  /// The ride shows cancelled but our cancel's answer never came: close
  /// anyway, and load the strikes / block from the server instead.
  void _exitWithoutCancelAnswer() {
    _cancelAnswerTimer = null;
    if (isClosed || state.exitReason != null) return;
    emit(state.copyWith(
      isCancelling: false,
      exitReason: RideTrackingExitReason.cancelledByUser,
    ));
    _accountBlock.refresh();
  }

  @override
  Future<void> close() {
    _cancelAnswerTimer?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
