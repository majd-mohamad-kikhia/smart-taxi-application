import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/open_trip_registry.dart';
import '../../data/models/driver_active_ride_event_model.dart';
import '../../data/models/driver_active_ride_model.dart';
import '../../data/repositories/driver_trip_repository.dart';
import '../../data/repositories/driver_trip_route_repository.dart';
import 'driver_active_ride_state.dart';

/// Finds rides the driver should be on and has no trip screen open for:
/// - at startup, `GET /api/driver/rides/active` — the driver was mid-ride
///   when the app last closed, so the shell puts them back on the trip
///   screen (and the waiting timer restarts from the server's
///   `elapsed_seconds`);
/// - `driver:active_ride` over the socket — sent on every connect and when
///   the office assigns a trip to the driver.
///
/// An in-progress ride is only opened when the route recorded so far is
/// still on the device: the driven distance is rebuilt from it, and
/// finishing without it would send a wrong distance.
class DriverActiveRideCubit extends Cubit<DriverActiveRideState> {
  final DriverTripRepository _repository;
  final DriverTripRouteRepository _routeRepository;
  final OpenTripRegistry _openTrips;
  late final StreamSubscription<Map<String, dynamic>> _socketSubscription;
  bool _checked = false;

  DriverActiveRideCubit(
    this._repository,
    this._routeRepository,
    this._openTrips,
    Stream<Map<String, dynamic>> socketActiveRides,
  ) : super(const DriverActiveRideState()) {
    _socketSubscription = socketActiveRides.listen(_handleSocketRide);
  }

  /// Checks once per app session; later calls are no-ops.
  Future<void> checkForActiveRide() async {
    if (_checked) return;
    _checked = true;
    try {
      final ride = await _repository.fetchActiveRide();
      if (ride != null) await _open(ride, isAssigned: false);
    } on DriverTripException catch (e) {
      // Not fatal: without it the driver just lands on the home tab.
      debugPrint(
        'DriverActiveRideCubit: active ride lookup failed: ${e.message}',
      );
    }
  }

  void _handleSocketRide(Map<String, dynamic> json) {
    final event = DriverActiveRideEventModel.tryParse(json);
    if (event == null) return;
    _open(event.ride, isAssigned: true);
  }

  Future<void> _open(DriverActiveRideModel ride, {required bool isAssigned}) async {
    final rideId = ride.order.rideId;
    if (isClosed || _openTrips.openRideId == rideId) return;
    if (ride.isInProgress) {
      final route = await _routeRepository.loadDraft(rideId);
      if (route == null) {
        debugPrint(
          'DriverActiveRideCubit: ride $rideId is in progress '
          'but has no saved route, not resuming',
        );
        return;
      }
      ride = ride.withRoute(route);
    }
    // Re-checked after the await: the REST lookup and the socket can report
    // the same ride at the same time.
    if (isClosed || _openTrips.openRideId == rideId) return;
    _openTrips.open(rideId);
    emit(DriverActiveRideState(
      ride: ride,
      isAssigned: isAssigned,
      version: state.version + 1,
    ));
  }

  @override
  Future<void> close() {
    _socketSubscription.cancel();
    return super.close();
  }
}
