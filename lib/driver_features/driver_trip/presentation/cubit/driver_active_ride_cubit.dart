import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/driver_trip_repository.dart';
import '../../data/repositories/driver_trip_route_repository.dart';
import 'driver_active_ride_state.dart';

/// Asks the server (`GET /api/driver/rides/active`) whether the driver was
/// mid-ride when the app last closed, so the shell can put them back on the
/// trip screen — and the waiting timer restarts from the server's
/// `elapsed_seconds`.
///
/// An in-progress ride is only resumed when the route recorded so far is
/// still on the device: the driven distance is rebuilt from it, and
/// finishing without it would send a wrong distance.
class DriverActiveRideCubit extends Cubit<DriverActiveRideState> {
  final DriverTripRepository _repository;
  final DriverTripRouteRepository _routeRepository;
  bool _checked = false;

  DriverActiveRideCubit(this._repository, this._routeRepository)
    : super(const DriverActiveRideState());

  /// Checks once per app session; later calls are no-ops.
  Future<void> checkForActiveRide() async {
    if (_checked) return;
    _checked = true;
    try {
      var ride = await _repository.fetchActiveRide();
      if (ride != null && ride.isInProgress) {
        final route = await _routeRepository.loadDraft(ride.order.rideId);
        if (route == null) {
          debugPrint(
            'DriverActiveRideCubit: ride ${ride.order.rideId} is in progress '
            'but has no saved route, not resuming',
          );
          return;
        }
        ride = ride.withRoute(route);
      }
      if (!isClosed && ride != null) emit(DriverActiveRideState(ride: ride));
    } on DriverTripException catch (e) {
      // Not fatal: without it the driver just lands on the home tab.
      debugPrint(
        'DriverActiveRideCubit: active ride lookup failed: ${e.message}',
      );
    }
  }
}
