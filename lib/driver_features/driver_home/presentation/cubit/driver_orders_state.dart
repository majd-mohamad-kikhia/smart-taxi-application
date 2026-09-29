import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';

class DriverOrdersState extends Equatable {
  final List<OrderOfferModel> orders;

  /// Set while an accept is in flight for this ride, so its card can show
  /// a spinner and every card's button can be disabled (only one accept
  /// at a time).
  final int? acceptingRideId;

  final String? errorMessage;

  const DriverOrdersState({
    this.orders = const [],
    this.acceptingRideId,
    this.errorMessage,
  });

  factory DriverOrdersState.initial() => const DriverOrdersState();

  DriverOrdersState copyWith({
    List<OrderOfferModel>? orders,
    int? acceptingRideId,
    bool clearAccepting = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverOrdersState(
      orders: orders ?? this.orders,
      acceptingRideId: clearAccepting ? null : (acceptingRideId ?? this.acceptingRideId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [orders, acceptingRideId, errorMessage];
}
