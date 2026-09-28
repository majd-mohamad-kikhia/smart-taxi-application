import 'package:equatable/equatable.dart';
import '../../data/location_ticker.dart';

/// Where the driver's live-location socket connection currently stands.
enum DriverPresenceStatus {
  /// Not connected — the driver toggled off, or never went online.
  offline,

  /// Connecting for the first time, or reconnecting after a drop.
  connecting,

  /// Connected and emitting `driver:location`.
  online,

  /// Permission denied, or the socket reported `connect_error`.
  error,
}

class DriverPresenceState extends Equatable {
  final DriverPresenceStatus status;
  final String? errorMessage;

  /// Set only when [errorMessage] came from [LocationPermissionDeniedException]
  /// — tells the UI which settings screen a "fix it" action should open.
  final LocationFailureReason? locationFailureReason;

  const DriverPresenceState({
    required this.status,
    this.errorMessage,
    this.locationFailureReason,
  });

  factory DriverPresenceState.initial() =>
      const DriverPresenceState(status: DriverPresenceStatus.offline);

  DriverPresenceState copyWith({
    DriverPresenceStatus? status,
    String? errorMessage,
    LocationFailureReason? locationFailureReason,
    bool clearError = false,
  }) {
    return DriverPresenceState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationFailureReason:
          clearError ? null : (locationFailureReason ?? this.locationFailureReason),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, locationFailureReason];
}
