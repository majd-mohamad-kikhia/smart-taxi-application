import 'package:equatable/equatable.dart';
import '../../data/models/route_session_model.dart';

class RouteTrackerState extends Equatable {
  /// The route being recorded, or the finished one being shown.
  final RouteSessionModel session;

  /// False until the saved route (if any) has been read from the device.
  final bool isLoaded;

  /// True while "start trip" is checking location permission.
  final bool isStarting;

  /// The driver's own position, once a GPS fix is known.
  final double? carLat;
  final double? carLng;

  /// True while the locate button is fetching a fix.
  final bool isLocating;

  /// Bumped every time the driver asks to be located, so the map recentres
  /// even when the position itself hasn't changed.
  final int locateRequest;

  final String? errorMessage;

  const RouteTrackerState({
    required this.session,
    this.isLoaded = false,
    this.isStarting = false,
    this.carLat,
    this.carLng,
    this.isLocating = false,
    this.locateRequest = 0,
    this.errorMessage,
  });

  factory RouteTrackerState.initial() =>
      const RouteTrackerState(session: RouteSessionModel.empty());

  RoutePhase get phase => session.phase;

  RouteTrackerState copyWith({
    RouteSessionModel? session,
    bool? isLoaded,
    bool? isStarting,
    double? carLat,
    double? carLng,
    bool? isLocating,
    int? locateRequest,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RouteTrackerState(
      session: session ?? this.session,
      isLoaded: isLoaded ?? this.isLoaded,
      isStarting: isStarting ?? this.isStarting,
      carLat: carLat ?? this.carLat,
      carLng: carLng ?? this.carLng,
      isLocating: isLocating ?? this.isLocating,
      locateRequest: locateRequest ?? this.locateRequest,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    session,
    isLoaded,
    isStarting,
    carLat,
    carLng,
    isLocating,
    locateRequest,
    errorMessage,
  ];
}
