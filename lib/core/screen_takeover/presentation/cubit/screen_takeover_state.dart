import 'package:equatable/equatable.dart';

/// The driver's "Open the app for new orders" switch.
class ScreenTakeoverState extends Equatable {
  /// False where the app can't open itself (iOS): the switch is not shown.
  final bool isSupported;

  /// Turned on, with every permission it needs allowed.
  final bool enabled;

  /// A permission screen is open, waiting for the driver.
  final bool isRequesting;

  /// Counts refusals from the switch, so each one is told to the driver
  /// once (a changing number is a new event, unlike a repeated message).
  final int permissionDeniedCount;

  const ScreenTakeoverState({
    this.isSupported = false,
    this.enabled = false,
    this.isRequesting = false,
    this.permissionDeniedCount = 0,
  });

  ScreenTakeoverState copyWith({
    bool? isSupported,
    bool? enabled,
    bool? isRequesting,
    int? permissionDeniedCount,
  }) {
    return ScreenTakeoverState(
      isSupported: isSupported ?? this.isSupported,
      enabled: enabled ?? this.enabled,
      isRequesting: isRequesting ?? this.isRequesting,
      permissionDeniedCount: permissionDeniedCount ?? this.permissionDeniedCount,
    );
  }

  @override
  List<Object?> get props => [
    isSupported,
    enabled,
    isRequesting,
    permissionDeniedCount,
  ];
}
