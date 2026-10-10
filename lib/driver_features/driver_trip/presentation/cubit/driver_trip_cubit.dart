import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/services/planned_route_loader.dart';
import '../../../../core/services/trip_route_tracker.dart';
import '../../data/datasources/driver_trip_location_service.dart';
import '../../data/datasources/open_trip_registry.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/driver_active_ride_event_model.dart';
import '../../data/models/driver_active_ride_model.dart';
import '../../data/route_distance_calculator.dart';
import '../../data/models/recorded_route_point_model.dart';
import '../../data/models/driver_ride_finish_model.dart';
import '../../data/models/ride_cancellation_model.dart';
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

  /// The most `distance_km` the server accepts.
  static const _maxDistanceKm = 2000.0;

  /// Longest the finish waits for a GPS fix before sending without one.
  static const _endFixTimeout = Duration(seconds: 5);

  /// How often a finish that found no connection is sent again.
  static const _finishRetryEvery = Duration(seconds: 8);

  final DriverTripRepository _repository;
  final DriverTripLocationService _locationService;
  final PlannedRouteLoader _routeLoader;
  final DriverTripRouteRepository _routeRepository;
  StreamSubscription<Position>? _positionSubscription;

  /// Draws the driver's road to the pickup while the trip hasn't started.
  final TripRouteTracker? _pickupRouteTracker;

  StreamSubscription<Position>? _pickupSubscription;
  Timer? _finishRetry;
  bool _finishInFlight = false;

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

  /// The ride being resumed after an app kill, if any.
  final DriverActiveRideModel? _resume;

  /// Last point recorded before the kill. The first fix after resuming is
  /// joined to it by a straight line, so the distance driven while the app
  /// was dead isn't lost entirely.
  RecordedRoutePointModel? _resumeAnchor;

  /// Cancels that arrive from outside — the customer, a manager or another
  /// of this driver's devices — over the socket, or over FCM when the
  /// socket is down. Both can report the same cancel; the first one wins.
  late final List<StreamSubscription<Map<String, dynamic>>> _cancellationSubscriptions;

  /// `driver:active_ride` — carries the office's edits to this trip.
  late final StreamSubscription<Map<String, dynamic>> _rideUpdateSubscription;
  final OpenTripRegistry _openTrips;

  DriverTripCubit(
    this._repository,
    this._locationService,
    this._routeLoader,
    this._routeRepository,
    this._openTrips,
    Stream<Map<String, dynamic>> socketCancellations,
    Stream<Map<String, dynamic>> pushCancellations,
    Stream<Map<String, dynamic>> socketRideUpdates,
    OrderOfferModel order, {
    DriverActiveRideModel? resume,
    TripRouteTracker? pickupRouteTracker,
  }) : _resume = resume,
       _pickupRouteTracker = pickupRouteTracker,
       super(
         DriverTripState.initial(
           order,
           status: _initialStatus(resume),
           waiting: resume?.waiting,
           pause: resume?.pause,
         ),
       ) {
    _openTrips.open(order.rideId);
    _cancellationSubscriptions = [
      socketCancellations.listen(_handleCancellation),
      pushCancellations.listen(_handleCancellation),
    ];
    _rideUpdateSubscription = socketRideUpdates.listen(_handleRideUpdate);
  }

  /// Merges the server's copy of this ride into the open trip. The office
  /// can move the points, change their details or the note until the trip
  /// starts; a moved point means the planned route is fetched again.
  void _handleRideUpdate(Map<String, dynamic> json) {
    final event = DriverActiveRideEventModel.tryParse(json);
    if (event == null ||
        isClosed ||
        event.rideId != state.order.rideId ||
        state.isCancelled ||
        state.status == DriverTripStatus.completed) {
      return;
    }
    final current = state.order;
    final updated = current.withUpdatedDetails(event.rideJson);
    if (updated == current) return;
    final pointsMoved = updated.pickupLat != current.pickupLat ||
        updated.pickupLng != current.pickupLng ||
        updated.dropoffLat != current.dropoffLat ||
        updated.dropoffLng != current.dropoffLng;
    if (pointsMoved) _routeLoader.reset();
    emit(state.copyWith(
      order: updated,
      routePoints: pointsMoved ? const [] : null,
      detailsUpdateCount:
          event.detailsUpdated ? state.detailsUpdateCount + 1 : null,
    ));
    if (pointsMoved && state.status == DriverTripStatus.inProgress) {
      _loadPlannedRoute();
    }
  }

  void _handleCancellation(Map<String, dynamic> json) {
    final event = RideCancellationModel.fromJson(json);
    if (event == null ||
        isClosed ||
        event.rideId != state.order.rideId ||
        state.isCancelled ||
        state.status == DriverTripStatus.completed) {
      return;
    }
    _finishRetry?.cancel();
    emit(state.copyWith(
      isCancelling: false,
      isCancelled: true,
      isFinishQueued: false,
      cancelledBy: event.cancelledBy,
    ));
  }

  static DriverTripStatus _initialStatus(DriverActiveRideModel? resume) {
    if (resume == null) return DriverTripStatus.accepted;
    if (resume.isInProgress) return DriverTripStatus.inProgress;
    return resume.isArrived ? DriverTripStatus.arrived : DriverTripStatus.accepted;
  }

  /// For an in-progress ride resumed after the app was killed: picks the
  /// trip back up from the route saved on the device — the driven distance,
  /// the recorded samples (so the route uploaded at finish is complete) and
  /// the line on the map — then restarts position tracking. Does nothing
  /// for a fresh ride or one still at pickup.
  void resumeIfNeeded() {
    final resume = _resume;
    if (resume == null || !resume.isInProgress || resume.resumedRoute.isEmpty) return;
    final route = resume.resumedRoute;
    _recordedRoute
      ..clear()
      ..addAll(route);
    _drivenMeters = RouteDistanceCalculator.meters(route);
    _resumeAnchor = route.last;
    emit(state.copyWith(
      drivenPath: [for (final p in route) RoutePointModel(p.lat, p.lng)],
    ));
    _loadPlannedRoute();
    _trackPosition();
  }

  /// Before the trip starts: follows the driver's position and keeps the
  /// Google road to the pickup on the map. Stops when the trip starts.
  Future<void> trackToPickup() async {
    final tracker = _pickupRouteTracker;
    if (tracker == null ||
        isClosed ||
        _pickupSubscription != null ||
        state.status == DriverTripStatus.inProgress ||
        state.status == DriverTripStatus.completed) {
      return;
    }
    Future<void> follow(Position position) async {
      if (isClosed || _pickupSubscription == null) return;
      emit(state.copyWith(carLat: position.latitude, carLng: position.longitude));
      try {
        final snapshot = await tracker.update(
          carLat: position.latitude,
          carLng: position.longitude,
          targetLat: state.order.pickupLat,
          targetLng: state.order.pickupLng,
        );
        if (isClosed || _pickupSubscription == null) return;
        if (snapshot.line.isNotEmpty) {
          emit(state.copyWith(pickupRoute: snapshot.line));
        }
      } catch (e) {
        debugPrint('DriverTripCubit: could not draw the road to the pickup: $e');
      }
    }

    _pickupSubscription = _locationService.positionStream().listen(follow);
    final start = await _locationService.currentPosition() ??
        await _locationService.lastKnownPosition();
    if (start != null) unawaited(follow(start));
  }

  void _stopPickupTracking() {
    _pickupSubscription?.cancel();
    _pickupSubscription = null;
    if (state.pickupRoute.isNotEmpty) emit(state.copyWith(pickupRoute: const []));
  }

  /// accepted → arrived. Optional: [startRide] works straight from accepted.
  /// The server starts the waiting timer; its reply seeds the on-screen one.
  Future<void> markArrived() => _advance(
    from: const {DriverTripStatus.accepted},
    to: DriverTripStatus.arrived,
    call: _repository.markArrived,
  );

  /// accepted / arrived → in_progress. [passengersCount] is sent only while
  /// the order has no number yet — an office order keeps the reception's.
  /// Stops the waiting timer — the server's reply carries the final fee.
  /// A 422 (more people than the car type takes) keeps the trip at pickup.
  Future<void> startRide({int? passengersCount}) async {
    const startableFrom = {DriverTripStatus.accepted, DriverTripStatus.arrived};
    if (isClosed || state.isBusy || !startableFrom.contains(state.status)) return;
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      final order = state.order;
      final sent = order.passengersCount == null ? passengersCount : null;
      final started = await _repository.startRide(order.rideId, passengersCount: sent);
      if (isClosed) return;
      _stopPickupTracking();
      final saved = started.passengersCount ?? order.passengersCount ?? sent;
      emit(state.copyWith(
        isUpdating: false,
        status: DriverTripStatus.inProgress,
        waiting: started.waiting,
        order: state.order.withPassengersCount(saved),
      ));
      _loadPlannedRoute();
      _trackPosition();
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isUpdating: false, errorMessage: e.message));
    }
  }

  /// Stops the trip for a while (the customer is buying a coffee, …). The
  /// status stays in progress; the server starts the pause timer and its
  /// reply seeds the on-screen one.
  Future<void> pauseTrip() => _changePause(
    allowed: () => !state.isPaused,
    call: _repository.pauseRide,
  );

  /// Ends the pause. The server's reply carries the pause totals, fee of
  /// the pause that just ended included.
  Future<void> resumeTrip() => _changePause(
    allowed: () => state.isPaused,
    call: _repository.resumeRide,
  );

  Future<void> _changePause({
    required bool Function() allowed,
    required Future<RidePauseModel?> Function(int rideId) call,
  }) async {
    if (isClosed || state.isBusy || state.status != DriverTripStatus.inProgress || !allowed()) {
      return;
    }
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      final pause = await call(state.order.rideId);
      if (!isClosed) emit(state.copyWith(isUpdating: false, pause: pause));
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isUpdating: false, errorMessage: e.message));
    }
  }

  /// in_progress → completed (also while paused: the server closes the
  /// pause first and counts its fee). Sends the distance actually driven so the
  /// server can compute the final price, and keeps the fare it returns.
  ///
  /// It never spins for ever: the call has a hard timeout, and any failure
  /// ends the spinner. With no connection the finish is kept
  /// ([DriverTripState.isFinishQueued]) and sent again every
  /// [_finishRetryEvery] until it goes through.
  Future<void> finishRide() async {
    if (isClosed || state.isBusy || state.status != DriverTripStatus.inProgress) return;
    _finishRetry?.cancel();
    emit(state.copyWith(isUpdating: true, clearError: true));
    await _sendFinish(automatic: false);
  }

  Future<void> _sendFinish({required bool automatic}) async {
    if (_finishInFlight ||
        isClosed ||
        state.isCancelled ||
        state.status != DriverTripStatus.inProgress) {
      return;
    }
    _finishInFlight = true;
    try {
      // The end is pinned once, by the driver's own tap; automatic retries
      // reuse it.
      if (!automatic) await _pinTripEnd();
      final finish = await _repository.finishRide(
        rideId: state.order.rideId,
        distanceKm: _distanceDrivenKm(),
      );
      if (!isClosed) _completeTrip(finish);
    } on DriverTripException catch (e) {
      if (isClosed) return;
      // The first call may have worked and only its answer been lost: the
      // retry then gets a 409. Ask the server; if it has the trip completed
      // this is just success, not an error.
      if (e.isConflict) {
        final done = await _finishedOnServer();
        if (isClosed) return;
        if (done != null) return _completeTrip(done);
      }
      _finishFailed(e, automatic: automatic);
    } catch (e) {
      debugPrint('DriverTripCubit: finish failed unexpectedly: $e');
      if (!isClosed) {
        _finishFailed(
          DriverTripException(AppStrings.current.errUnexpected),
          automatic: automatic,
        );
      }
    } finally {
      _finishInFlight = false;
    }
  }

  /// Pins the end of the trip so the last stretch is counted too. A GPS that
  /// is slow, off or refused must not hold the finish up.
  Future<void> _pinTripEnd() async {
    try {
      final end = await _locationService.currentPosition().timeout(_endFixTimeout);
      if (end == null) return;
      _accumulateDistance(end);
      _latestFix = end;
      _recordSample();
    } catch (e) {
      debugPrint('DriverTripCubit: could not pin the trip end: $e');
    }
  }

  Future<DriverRideFinishModel?> _finishedOnServer() async {
    try {
      return await _repository.fetchFinishedActiveRide();
    } on DriverTripException catch (e) {
      debugPrint('DriverTripCubit: could not check the ride: ${e.message}');
      return null;
    }
  }

  void _completeTrip(DriverRideFinishModel finish) {
    _finishRetry?.cancel();
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
      isFinishQueued: false,
      status: DriverTripStatus.completed,
      fare: finish.fare,
      orderSource: finish.orderSource,
      customer: finish.customer,
      completedAt: finish.completedAt,
    ));
  }

  void _finishFailed(DriverTripException e, {required bool automatic}) {
    if (e.isNetwork) {
      // Nothing was refused: keep the finish and try again soon. A retry
      // that fails the same way again says nothing new.
      emit(state.copyWith(
        isUpdating: false,
        isFinishQueued: true,
        errorMessage: automatic ? null : e.message,
      ));
      _finishRetry = Timer(_finishRetryEvery, () => _sendFinish(automatic: true));
      return;
    }
    _finishRetry?.cancel();
    emit(state.copyWith(
      isUpdating: false,
      isFinishQueued: false,
      errorMessage: e.message,
    ));
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
      _finishRetry?.cancel();
      if (!isClosed) {
        emit(state.copyWith(isCancelling: false, isCancelled: true, isFinishQueued: false));
      }
    } on DriverTripException catch (e) {
      if (!isClosed) emit(state.copyWith(isCancelling: false, errorMessage: e.message));
    }
  }

  Future<void> _advance({
    required Set<DriverTripStatus> from,
    required DriverTripStatus to,
    required Future<RideWaitingModel?> Function(int rideId) call,
  }) async {
    if (isClosed || state.isBusy || !from.contains(state.status)) return;
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      final waiting = await call(state.order.rideId);
      if (isClosed) return;
      emit(state.copyWith(isUpdating: false, status: to, waiting: waiting));
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
      if (start.accuracy <= _maxAccuracyMeters) _bridgeResumeGap(start);
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
    } else {
      _bridgeResumeGap(position);
    }
    _lastCounted = position;
    _recordPathPoint(position);
  }

  /// First fix after a resume: adds the straight line from the last point
  /// saved before the app was killed. Used once.
  void _bridgeResumeGap(Position position) {
    final anchor = _resumeAnchor;
    if (anchor == null) return;
    _resumeAnchor = null;
    _drivenMeters += _locationService.distanceFromPoint(anchor.lat, anchor.lng, position);
  }

  /// Adds the latest GPS fix to the route that is uploaded after finish, and
  /// saves a copy on the device after every sample — if the app is killed
  /// mid-trip, that copy is what the driven distance is rebuilt from.
  void _recordSample() {
    final fix = _latestFix;
    if (isClosed || fix == null) return;
    _recordedRoute.add(RecordedRoutePointModel(
      lat: fix.latitude,
      lng: fix.longitude,
      recordedAt: DateTime.now(),
    ));
    unawaited(_routeRepository.saveDraft(state.order.rideId, List.of(_recordedRoute)));
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
  /// quoted distance when GPS never produced a usable fix. Always a real
  /// number from 0 to [_maxDistanceKm]: the server answers 422 to anything
  /// else (missing, NaN, negative, above the limit).
  double _distanceDrivenKm() {
    final km = _drivenMeters / 1000;
    debugPrint('DriverTripCubit: measured ${km.toStringAsFixed(3)} km driven');
    var value = km.isFinite && km > 0 ? km : state.order.distanceKm;
    if (!value.isFinite || value < 0) value = 0;
    return double.parse(value.clamp(0, _maxDistanceKm).toStringAsFixed(2));
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
    for (final subscription in _cancellationSubscriptions) {
      subscription.cancel();
    }
    _rideUpdateSubscription.cancel();
    _openTrips.close(state.order.rideId);
    _recordTimer?.cancel();
    _finishRetry?.cancel();
    _positionSubscription?.cancel();
    _pickupSubscription?.cancel();
    return super.close();
  }
}
