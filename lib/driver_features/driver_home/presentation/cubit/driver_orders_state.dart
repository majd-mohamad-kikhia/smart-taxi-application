import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';

class DriverOrdersState extends Equatable {
  final List<OrderOfferModel> orders;

  /// Set while an accept is in flight for this ride, so its card can show
  /// a spinner and every card's button can be disabled (only one accept
  /// at a time).
  final int? acceptingRideId;

  /// The offer the driver is looking at: its route is drawn on the home map
  /// and its card is shown. Falls back to the first offer when it is unset
  /// or no longer on the list — see [selectedOrder].
  final int? selectedRideId;

  final String? errorMessage;

  /// [errorMessage] is the "charge your wallet first" refusal: shown as a
  /// dialog the driver has to see, not a passing toast.
  final bool errorIsWalletTooLow;

  const DriverOrdersState({
    this.orders = const [],
    this.acceptingRideId,
    this.selectedRideId,
    this.errorMessage,
    this.errorIsWalletTooLow = false,
  });

  factory DriverOrdersState.initial() => const DriverOrdersState();

  /// Position of the offer being looked at in [orders]; 0 when there are no
  /// offers.
  int get selectedIndex {
    final index = orders.indexWhere((o) => o.rideId == selectedRideId);
    return index < 0 ? 0 : index;
  }

  /// The offer being looked at, or null when there are none.
  OrderOfferModel? get selectedOrder =>
      orders.isEmpty ? null : orders[selectedIndex];

  DriverOrdersState copyWith({
    List<OrderOfferModel>? orders,
    int? acceptingRideId,
    int? selectedRideId,
    bool clearAccepting = false,
    String? errorMessage,
    bool errorIsWalletTooLow = false,
    bool clearError = false,
  }) {
    return DriverOrdersState(
      orders: orders ?? this.orders,
      acceptingRideId: clearAccepting
          ? null
          : (acceptingRideId ?? this.acceptingRideId),
      selectedRideId: selectedRideId ?? this.selectedRideId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorIsWalletTooLow: clearError
          ? false
          : (errorMessage != null
                ? errorIsWalletTooLow
                : this.errorIsWalletTooLow),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    acceptingRideId,
    selectedRideId,
    errorMessage,
    errorIsWalletTooLow,
  ];
}
