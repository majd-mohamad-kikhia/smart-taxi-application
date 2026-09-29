import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/services/planned_route_loader.dart';
import '../../data/datasources/driver_trip_location_service.dart';
import '../../data/models/recorded_route_point_model.dart';
import '../../data/repositories/driver_trip_repository.dart';
import '../../data/repositories/driver_trip_route_repository.dart';
import 'driver_trip_state.dart';

/// Drives the driver's active-ride screen for the one ride they just
/// accepted. Every action goes through the matching
/// `POST /api/driver/rides/:id/*` endpoint and only advances
/// [DriverTripState.status] once the server confirms it. While the ride is
/// in progress it also streams the driver's position for the live map,
/// loads the planned road route once, records the path actually driven
/// (drawn as a second line), measures that distance for the fare, and
/// records a GPS sample every 5 s to upload as the trip's route after finish.
class DriverTripCubit extends Cubit<DriverTripState> {
  static const _maxAccuracyMeters = 100;
  static const _recordInterval = Duration(seconds: 5);

  /// Every Nth recorded point the route so far is also saved on the device.
  static const _draftEveryPoints = 6;

  final DriverTripRepository _repository;
  final DriverTripLocationService _locationService;
  final PlannedRouteLoader _routeLoader;
  final DriverTripRouteRepository _routeRepository;
  StreamSubscription<Position>? _positionSubscription;

  /// GPS distance accumulated since the ride started, and the last GPS
  /// fix it was measured from.
  double _drivenMeters = 0;
  Position? _lastCounted;

  /// The route sent to the backend: one sample every [_recordInterval]
  /// from Start to Finish, taken from [_latestFix]. Not part of the state —
  /// nothing on screen depends on it.
  final List<RecordedRoutePointModel> _recordedRoute = [];
  Timer? _recordTimer;
  Position? _latestFix;

  DriverTripCubit(
    this._repository,
    this._locationService,
    this._routeLoader,
    this._routeRepository,
    OrderOfferModel order,
  ) : super(DriverTripState.initial(order));

  /// accepted → arrived. Optional: [startRide] works straight from accepted.
  Future<void> markArrived() => _advance(
    from: const {DriverTripStatus.accepted},
    to: DriverTripStatus.arrived,
    call: _repository.markArrived,
  );

  /// accepted / arrived → in_progress.
  Future<void> startRide() => _advance(
    from: const {DriverTripStatus.accepted, DriverTripStatus.arrived},
    to: DriverTripStatus.inProgress,
    call: _repository.startRide,
  );

  /// in_progress → completed. Sends the distance actually driven so the
  /// server can compute the final price, and keeps the fare it returns.
  Future<void> finishRide() async {
    if (isClosed || state.isBusy || state.status != DriverTripStatus.inProgress) return;
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      // Pin the end of the trip so the last stretch is counted too.
      final end = await _locationService.currentPosition();
      if (end != null) {
        _accumulateDistance(end);
        _latestFix = end;
        _recordSample();
      }
      final fare = await _repository.finishRide(
        rideId: state.order.rideId,
        distanceKm: _distanceDrivenKm(),
      );
      if (isClosed) return;
      _positionSubscription?.cancel();
      _recordTimer?.cancel();
      // Fire and forget: the repository retries on its own and never throws,
      // so the route can't hold up the fare / payment dialog.
      unawaited(_routeRepository.finishAndUpload(
        state.order.rideId,
        List.of(_recordedRoute),
      ));
      emit(state.copyWith(
        isUpdating: false,
        status: DriverTripStatus.completed,
        fare: fare,
      ));
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isUpdating: false, errorMessage: e.message));
    }
  }

  /// completed + unpaid → paid. The driver taps this once the customer has
  /// paid cash; the server splits the money and deducts the commission.
  Future<void> confirmPayment() async {
    if (isClosed ||
        state.status != DriverTripStatus.completed ||
        state.isConfirmingPayment ||
        state.isPaid) {
      return;
    }
    emit(state.copyWith(isConfirmingPayment: true, clearError: true));
    try {
      final payment = await _repository.confirmPayment(state.order.rideId);
      if (!isClosed) {
        emit(state.copyWith(isConfirmingPayment: false, isPaid: true, payment: payment));
      }
    } on DriverTripException catch (e) {
      if (isClosed) return;
      // The ride is already finished at this point, so a 409 means the
      // payment was confirmed elsewhere — another device, or a manager
      // settling it — and the money is already split. Nothing is deducted
      // twice; just let the driver move on.
      emit(e.isConflict
          ? state.copyWith(isConfirmingPayment: false, isPaid: true)
          : state.copyWith(isConfirmingPayment: false, errorMessage: e.message));
    }
  }

  Future<void> cancelRide(String reason) async {
    if (isClosed || state.isBusy || state.status == DriverTripStatus.completed) return;
    emit(state.copyWith(isCancelling: true, clearError: true));
    try {
      await _repository.cancelRide(rideId: state.order.rideId, cancellationReason: reason);
      if (!isClosed) emit(state.copyWith(isCancelling: false, isCancelled: true));
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isCancelling: false, errorMessage: e.message));
    }
  }

  Future<void> _advance({
    required Set<DriverTripStatus> from,
    required DriverTripStatus to,
    required Future<void> Function(int rideId) call,
  }) async {
    if (isClosed || state.isBusy || !from.contains(state.status)) return;
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await call(state.order.rideId);
      if (isClosed) return;
      emit(state.copyWith(isUpdating: false, status: to));
      if (to == DriverTripStatus.inProgress) {
        _loadPlannedRoute();
        _trackPosition();
      }
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isUpdating: false, errorMessage: e.message));
    }
  }

  Future<void> _trackPosition() async {
    // Subscribe first so no movement is missed while the start fix loads.
    _recordTimer = Timer.periodic(_recordInterval, (_) => _recordSample());
    _positionSubscription = _locationService.positionStream().listen((position) {
      if (position.accuracy <= _maxAccuracyMeters) _latestFix = position;
      _accumulateDistance(position);
      _updatePosition(position);
      _loadPlannedRoute();
    });

    final start = await _locationService.currentPosition() ??
        await _locationService.lastKnownPosition();
    if (isClosed || start == null) return;
    // Baseline for the driven distance, unless a streamed fix already set one.
    if (_lastCounted == null) {
      _lastCounted = start;
      _recordPathPoint(start);
    }
    if (_latestFix == null) {
      _latestFix = start;
      _recordSample();
    }
    if (state.carLat == null) _updatePosition(start);
  }

  void _accumulateDistance(Position position) {
    if (position.accuracy > _maxAccuracyMeters) return;
    final previous = _lastCounted;
    if (previous != null) {
      _drivenMeters += _locationService.distanceMeters(previous, position);
    }
    _lastCounted = position;
    _recordPathPoint(position);
  }

  /// Adds the latest GPS fix to the route that is uploaded after finish, and
  /// saves a safety copy on the device every [_draftEveryPoints] samples.
  void _recordSample() {
    final fix = _latestFix;
    if (isClosed || fix == null) return;
    _recordedRoute.add(RecordedRoutePointModel(
      lat: fix.latitude,
      lng: fix.longitude,
      recordedAt: DateTime.now(),
    ));
    if (_recordedRoute.length % _draftEveryPoints == 0) {
      unawaited(_routeRepository.saveDraft(state.order.rideId, List.of(_recordedRoute)));
    }
  }

  void _recordPathPoint(Position position) {
    if (isClosed) return;
    emit(state.copyWith(
      drivenPath: [
        ...state.drivenPath,
        RoutePointModel(position.latitude, position.longitude),
      ],
    ));
  }

  /// Distance for the finish call, rounded to 2 decimals. Falls back to the
  /// quoted distance when GPS never produced a usable fix, since the server
  /// rejects a missing or zero `distance_km`.
  double _distanceDrivenKm() {
    final km = _drivenMeters / 1000;
    debugPrint('DriverTripCubit: measured ${km.toStringAsFixed(3)} km driven');
    final value = km > 0 ? km : state.order.distanceKm;
    return double.parse(value.toStringAsFixed(2));
  }

  void _updatePosition(Position position) {
    if (isClosed) return;
    emit(state.copyWith(carLat: position.latitude, carLng: position.longitude));
  }

  /// Loads the planned pickup → dropoff route. Fixed once loaded; while it
  /// isn't available yet the loader retries on later calls.
  Future<void> _loadPlannedRoute() async {
    final order = state.order;
    final route = await _routeLoader.load(
      fromLat: order.pickupLat,
      fromLng: order.pickupLng,
      toLat: order.dropoffLat,
      toLng: order.dropoffLng,
    );
    if (!isClosed) emit(state.copyWith(routePoints: route));
  }

  @override
  Future<void> close() {
    _recordTimer?.cancel();
    _positionSubscription?.cancel();
    return super.close();
  }
}
