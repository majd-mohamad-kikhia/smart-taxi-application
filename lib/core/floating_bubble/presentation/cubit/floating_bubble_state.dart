import 'package:equatable/equatable.dart';

/// The driver's "Floating bubble" switch.
class FloatingBubbleState extends Equatable {
  /// False where the bubble can't exist (iOS): the switch is not shown.
  final bool isSupported;

  /// Turned on, with "Display over other apps" allowed.
  final bool enabled;

  /// The permission screen is open, waiting for the driver.
  final bool isRequesting;

  /// Counts refusals of the permission, so each one is told to the driver
  /// once (a changing number is a new event, unlike a repeated message).
  final int permissionDeniedCount;

  const FloatingBubbleState({
    this.isSupported = false,
    this.enabled = false,
    this.isRequesting = false,
    this.permissionDeniedCount = 0,
  });

  FloatingBubbleState copyWith({
    bool? isSupported,
    bool? enabled,
    bool? isRequesting,
    int? permissionDeniedCount,
  }) {
    return FloatingBubbleState(
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
