import 'package:equatable/equatable.dart';

/// What the customer sees under "arrives in": the remaining road distance
/// and travel time, already rounded to what is displayed — so the ticks that
/// don't change the label also don't change the state (no rebuild).
class TripEtaModel extends Equatable {
  /// Below this the distance is shown in meters, above it in kilometers.
  static const int metersThreshold = 1000;

  final int distanceMeters;
  final int minutes;

  const TripEtaModel({required this.distanceMeters, required this.minutes});

  /// Rounds the raw remaining [meters] / [seconds]: a whole minute (never
  /// less than 1), and the distance to the nearest 50 m under 1 km or
  /// 100 m above it — the same steps its label has.
  factory TripEtaModel.fromRemaining({
    required double meters,
    required double seconds,
  }) {
    final step = meters < metersThreshold ? 50 : 100;
    return TripEtaModel(
      distanceMeters: (meters / step).round() * step,
      minutes: (seconds / 60).round().clamp(1, 24 * 60),
    );
  }

  @override
  List<Object?> get props => [distanceMeters, minutes];
}
