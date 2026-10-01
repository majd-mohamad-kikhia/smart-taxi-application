import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../data/datasources/route_location_service.dart';
import '../../data/models/route_session_model.dart';
import '../../data/repositories/route_session_repository.dart';
import 'route_tracker_state.dart';

/// Drives the driver's private "route" tab: the same steps as an accepted
/// ride — arrived, start trip, stops (coffee), finish — but entirely on the
/// device. Nothing is sent to the server or to anyone else.
///
/// While the trip runs it follows the GPS, drawing the path and adding up
/// the distance. The whole route is saved on the device as it goes (and
/// kept after finishing) until [startNewRoute] clears it, so closing the
/// app mid-route doesn't lose it.
class RouteTrackerCubit extends Cubit<RouteTrackerState> {
  static const _maxAccuracyMeters = 100;

  /// A fix only becomes a path point once it is this far from the last one,
  /// which drops GPS jitter and keeps the saved route small.
  static const _minPointGapMeters = 10;

  /// Trip-time saves are spread out; every step change is saved at once.
  static const _saveInterval = Duration(seconds: 5);

  final RouteSessionRepository _repository;
  final RouteLocationService _locationService;
  final CurrentLocationService _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastSavedAt;

  RouteTrackerCubit(
    this._repository,
    this._locationService,
    this._currentLocation,
  ) : super(RouteTrackerState.initial());

  /// Restores the saved route. A trip that was still running when the app
  /// closed picks up tracking again; the first new fix is joined to the
  /// last saved point, so the gap is covered by a straight line.
  Future<void> load() async {
    final saved = await _repository.load();
    if (isClosed) return;
    emit(
      state.copyWith(
        session: saved ?? const RouteSessionModel.empty(),
        isLoaded: true,
      ),
    );
    if (state.phase == RoutePhase.inProgress) {
      _startTracking();
    } else {
      _showLastKnownPosition();
    }
  }

  /// idle → waiting: starts the waiting timer.
  Future<void> markArrived() async {
    if (state.phase != RoutePhase.idle) return;
    await _update(
      state.session.copyWith(
        phase: RoutePhase.waiting,
        arrivedAt: DateTime.now(),
      ),
    );
  }

  /// idle / waiting → in progress. Needs location, since the whole point is
  /// the recorded route.
  Future<void> startTrip() async {
    final phase = state.phase;
    if (state.isStarting ||
        (phase != RoutePhase.idle && phase != RoutePhase.waiting)) {
      return;
    }
    emit(state.copyWith(isStarting: true, clearError: true));
    final allowed = await _locationService.ensurePermission();
    if (isClosed) return;
    if (!allowed) {
      emit(
        state.copyWith(
          isStarting: false,
          errorMessage: AppStrings.current.routeLocationDenied,
        ),
      );
      return;
    }
    await _update(
      state.session.copyWith(
        phase: RoutePhase.inProgress,
        startedAt: DateTime.now(),
        distanceMeters: 0,
        points: const [],
      ),
    );
    if (isClosed) return;
    emit(state.copyWith(isStarting: false));
    _startTracking();
  }

  /// Starts a stop (the customer is buying a coffee, …).
  Future<void> pauseTrip() async {
    final session = state.session;
    if (session.phase != RoutePhase.inProgress || session.isPaused) return;
    await _update(
      session.copyWith(
        pauses: [
          ...session.pauses,
          RoutePauseRecordModel(startedAt: DateTime.now()),
        ],
      ),
    );
  }

  /// Ends the running stop.
  Future<void> resumeTrip() async {
    final session = state.session;
    if (session.phase != RoutePhase.inProgress || !session.isPaused) return;
    await _update(
      session.copyWith(pauses: _withOpenPauseClosed(session, DateTime.now())),
    );
  }

  /// in progress → finished (also while stopped: the stop is closed first).
  /// Pins the end of the route with one last GPS fix and stops tracking.
  Future<void> finishTrip() async {
    if (state.phase != RoutePhase.inProgress) return;
    final finishedAt = DateTime.now();
    final end = await _locationService.currentPosition();
    if (isClosed) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    var session = state.session;
    if (end != null) session = _withFix(session, end);
    await _update(
      session.copyWith(
        phase: RoutePhase.finished,
        finishedAt: finishedAt,
        pauses: _withOpenPauseClosed(session, finishedAt),
      ),
    );
  }

  /// The locate button: finds the driver right now, moves the yellow pin
  /// there and asks the map to centre on it. Works in every step, and never
  /// touches the recorded route.
  Future<void> locateMe() async {
    if (state.isLocating) return;
    emit(state.copyWith(isLocating: true, clearError: true));
    try {
      // The same one-shot GPS read the location picker's button uses.
      final position = await _currentLocation.getCurrentLocation();
      if (isClosed) return;
      emit(
        state.copyWith(
          isLocating: false,
          carLat: position.latitude,
          carLng: position.longitude,
          locateRequest: state.locateRequest + 1,
        ),
      );
    } on LocationPermissionDeniedException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLocating: false,
          errorMessage: e.reason == LocationFailureReason.serviceDisabled
              ? AppStrings.current.errLocationServiceOff
              : AppStrings.current.errLocationDenied,
        ),
      );
    }
  }

  /// finished → idle: forgets the saved route and starts over.
  Future<void> startNewRoute() async {
    if (state.phase != RoutePhase.finished) return;
    await _repository.clear();
    _lastSavedAt = null;
    if (isClosed) return;
    emit(
      state.copyWith(
        session: const RouteSessionModel.empty(),
        clearError: true,
      ),
    );
  }

  List<RoutePauseRecordModel> _withOpenPauseClosed(
    RouteSessionModel session,
    DateTime at,
  ) {
    if (!session.isPaused) return session.pauses;
    return [
      ...session.pauses.take(session.pauses.length - 1),
      session.pauses.last.closedAt(at),
    ];
  }

  /// Emits the new session and saves it immediately.
  Future<void> _update(RouteSessionModel session) async {
    if (isClosed) return;
    emit(state.copyWith(session: session));
    _lastSavedAt = DateTime.now();
    await _repository.save(session);
  }

  Future<void> _showLastKnownPosition() async {
    final position = await _locationService.lastKnownPosition();
    if (isClosed || position == null || state.carLat != null) return;
    emit(state.copyWith(carLat: position.latitude, carLng: position.longitude));
  }

  Future<void> _startTracking() async {
    // Subscribe before anything is awaited so no early fix is missed.
    final previous = _positionSubscription;
    _positionSubscription = _locationService.positionStream().listen(
      _onFix,
      onError: (Object error) =>
          debugPrint('RouteTrackerCubit: position stream error: $error'),
    );
    await previous?.cancel();
    // The first pin, and the start of the path when none exists yet.
    final start =
        await _locationService.currentPosition() ??
        await _locationService.lastKnownPosition();
    if (start != null && !isClosed && state.phase == RoutePhase.inProgress) {
      _onFix(start);
    }
  }

  void _onFix(Position position) {
    if (isClosed) return;
    final before = state.session;
    final session = state.phase == RoutePhase.inProgress
        ? _withFix(before, position)
        : before;
    emit(
      state.copyWith(
        session: session,
        carLat: position.latitude,
        carLng: position.longitude,
      ),
    );
    // `_withFix` returns the same object when the fix didn't count.
    if (!identical(session, before)) _saveThrottled(session);
  }

  void _saveThrottled(RouteSessionModel session) {
    final last = _lastSavedAt;
    if (last != null && DateTime.now().difference(last) < _saveInterval) return;
    _lastSavedAt = DateTime.now();
    unawaited(_repository.save(session));
  }

  /// [session] with [position] added to the path and the distance, or
  /// [session] itself when the fix is too inaccurate or too close to the
  /// last point to count.
  RouteSessionModel _withFix(RouteSessionModel session, Position position) {
    if (position.accuracy > _maxAccuracyMeters) return session;
    final last = session.points.isEmpty ? null : session.points.last;
    var distance = session.distanceMeters;
    if (last != null) {
      final gap = _locationService.distanceMeters(
        last.lat,
        last.lng,
        position.latitude,
        position.longitude,
      );
      if (gap < _minPointGapMeters) return session;
      distance += gap;
    }
    return session.copyWith(
      distanceMeters: distance,
      points: [
        ...session.points,
        RoutePointModel(position.latitude, position.longitude),
      ],
    );
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
