import 'package:equatable/equatable.dart';
import '../../../driver_trip/data/models/driver_active_ride_model.dart';
import '../../data/models/shared_order_preview_model.dart';

sealed class SharedOrderState extends Equatable {
  const SharedOrderState();

  @override
  List<Object?> get props => [];
}

final class SharedOrderLoading extends SharedOrderState {
  const SharedOrderLoading();
}

/// The order is on screen. Accept shows only while
/// `preview.canAccept`; [acceptError] is set when the last accept failed
/// without an answer (offline) — it is safe to tap again; [walletMessage]
/// is the server's text when it refused because the wallet is too low
/// (nothing was accepted; the order is still there to accept after a
/// top-up).
final class SharedOrderLoaded extends SharedOrderState {
  final SharedOrderPreviewModel preview;
  final bool accepting;
  final String? acceptError;
  final String? walletMessage;

  /// The driver has a trip screen open (for "finish your current trip").
  final bool hasOpenTrip;

  const SharedOrderLoaded(
    this.preview, {
    this.accepting = false,
    this.acceptError,
    this.walletMessage,
    this.hasOpenTrip = false,
  });

  /// A new attempt or a refusal replaces the last one: [acceptError] and
  /// [walletMessage] are cleared unless given.
  SharedOrderLoaded copyWith({bool? accepting, String? acceptError, String? walletMessage}) {
    return SharedOrderLoaded(
      preview,
      accepting: accepting ?? this.accepting,
      acceptError: acceptError,
      walletMessage: walletMessage,
      hasOpenTrip: hasOpenTrip,
    );
  }

  @override
  List<Object?> get props => [preview, accepting, acceptError, walletMessage, hasOpenTrip];
}

/// Nobody can take the order any more: [availability] is `taken` or
/// `cancelled`. [preview] is the last order seen, when there was one.
final class SharedOrderClosed extends SharedOrderState {
  final SharedOrderAvailability availability;
  final SharedOrderPreviewModel? preview;

  const SharedOrderClosed(this.availability, {this.preview});

  @override
  List<Object?> get props => [availability, preview];
}

/// This driver got the order: open the trip screen with [ride].
final class SharedOrderAccepted extends SharedOrderState {
  final DriverActiveRideModel ride;

  const SharedOrderAccepted(this.ride);

  @override
  List<Object?> get props => [ride];
}

/// The order is already this driver's trip and its screen is open (or
/// can't be reopened from here): just go back to it.
final class SharedOrderBackToTrip extends SharedOrderState {
  const SharedOrderBackToTrip();
}

final class SharedOrderInvalidLink extends SharedOrderState {
  const SharedOrderInvalidLink();
}

/// The first load failed (offline, server error) — [message] says why.
final class SharedOrderFailure extends SharedOrderState {
  final String message;

  const SharedOrderFailure(this.message);

  @override
  List<Object?> get props => [message];
}
