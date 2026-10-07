import 'package:equatable/equatable.dart';

/// How long the driver needs to reach the pickup point, as the server
/// worked it out when the ride was accepted (`eta` of the accept reply).
class PickupEtaModel extends Equatable {
  final int durationSeconds;

  /// [durationSeconds] rounded up, at least 1 — ready to show.
  final int durationMinutes;
  final int distanceMeters;

  const PickupEtaModel({
    required this.durationSeconds,
    required this.durationMinutes,
    required this.distanceMeters,
  });

  /// Null when [json] is no `eta` object or has no usable minutes (the
  /// server sends `eta: null` when it could not work the time out).
  static PickupEtaModel? tryParse(Object? json) {
    if (json is! Map) return null;
    final minutes = json['duration_minutes'];
    if (minutes is! num || minutes < 1) return null;
    return PickupEtaModel(
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? minutes.toInt() * 60,
      durationMinutes: minutes.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [durationSeconds, durationMinutes, distanceMeters];
}
