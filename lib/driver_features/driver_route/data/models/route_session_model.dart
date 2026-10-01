import 'package:equatable/equatable.dart';
import '../../../../core/models/route_point_model.dart';

/// Where the driver is in a locally tracked route:
/// idle → waiting (tapped arrived) → inProgress → finished.
enum RoutePhase { idle, waiting, inProgress, finished }

/// One stop during the route (e.g. for a coffee). [endedAt] is null while
/// the stop is still running.
class RoutePauseRecordModel extends Equatable {
  final DateTime startedAt;
  final DateTime? endedAt;

  const RoutePauseRecordModel({required this.startedAt, this.endedAt});

  factory RoutePauseRecordModel.fromJson(Map<String, dynamic> json) {
    final ended = json['ended_at'] as String?;
    return RoutePauseRecordModel(
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: ended == null ? null : DateTime.parse(ended),
    );
  }

  Map<String, dynamic> toJson() => {
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
  };

  bool get isRunning => endedAt == null;

  Duration durationAt(DateTime now) => (endedAt ?? now).difference(startedAt);

  RoutePauseRecordModel closedAt(DateTime time) =>
      RoutePauseRecordModel(startedAt: startedAt, endedAt: time);

  @override
  List<Object?> get props => [startedAt, endedAt];
}

/// Everything the driver's private "route" tab records: when they arrived,
/// when the trip started and ended, every stop, the distance and the path
/// driven. Purely local — nothing here is ever sent to the server.
///
/// All durations are measured with the phone's own clock. Pass `now` to the
/// duration getters so a live screen and a finished summary share one
/// definition.
class RouteSessionModel extends Equatable {
  final RoutePhase phase;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<RoutePauseRecordModel> pauses;
  final double distanceMeters;
  final List<RoutePointModel> points;

  const RouteSessionModel({
    required this.phase,
    this.arrivedAt,
    this.startedAt,
    this.finishedAt,
    this.pauses = const [],
    this.distanceMeters = 0,
    this.points = const [],
  });

  const RouteSessionModel.empty() : this(phase: RoutePhase.idle);

  factory RouteSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return RouteSessionModel(
      phase: RoutePhase.values.byName(json['phase'] as String),
      arrivedAt: time('arrived_at'),
      startedAt: time('started_at'),
      finishedAt: time('finished_at'),
      pauses: (json['pauses'] as List)
          .map(
            (p) => RoutePauseRecordModel.fromJson(
              Map<String, dynamic>.from(p as Map),
            ),
          )
          .toList(),
      distanceMeters: (json['distance_m'] as num).toDouble(),
      points: (json['points'] as List)
          .map(
            (p) => RoutePointModel(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'arrived_at': arrivedAt?.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'finished_at': finishedAt?.toIso8601String(),
    'pauses': pauses.map((p) => p.toJson()).toList(),
    'distance_m': distanceMeters,
    'points': [
      for (final p in points) [p.lat, p.lng],
    ],
  };

  bool get isPaused => pauses.isNotEmpty && pauses.last.isRunning;
  int get pauseCount => pauses.length;

  /// From "arrived" to "start trip" (still counting while waiting).
  Duration waitingDuration(DateTime now) {
    final arrived = arrivedAt;
    if (arrived == null) return Duration.zero;
    return (startedAt ?? now).difference(arrived);
  }

  /// From "start trip" to "finish" (still counting while in progress).
  Duration tripDuration(DateTime now) {
    final started = startedAt;
    if (started == null) return Duration.zero;
    return (finishedAt ?? now).difference(started);
  }

  /// All stops together, the running one included.
  Duration pausedDuration(DateTime now) =>
      pauses.fold(Duration.zero, (total, p) => total + p.durationAt(now));

  /// The stop that is running now, or zero.
  Duration currentPauseDuration(DateTime now) =>
      isPaused ? pauses.last.durationAt(now) : Duration.zero;

  /// Trip time without the stops.
  Duration drivingDuration(DateTime now) =>
      tripDuration(now) - pausedDuration(now);

  RouteSessionModel copyWith({
    RoutePhase? phase,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<RoutePauseRecordModel>? pauses,
    double? distanceMeters,
    List<RoutePointModel>? points,
  }) {
    return RouteSessionModel(
      phase: phase ?? this.phase,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      pauses: pauses ?? this.pauses,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    arrivedAt,
    startedAt,
    finishedAt,
    pauses,
    distanceMeters,
    points,
  ];
}
