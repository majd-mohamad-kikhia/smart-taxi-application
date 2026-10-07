import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../data/datasources/driver_socket_service.dart';
import '../../data/models/order_accept_result_model.dart';
import 'driver_orders_state.dart';
import 'driver_presence_cubit.dart';
import 'driver_presence_state.dart';

/// Drives the driver home screen's ride-offer cards.
///
/// Purely event-fed: cards come from `driver:orders_snapshot` (full
/// replace on connect), `driver:order_offer` (upsert) and
/// `driver:order_remove` (drop) over the socket [DriverPresenceCubit]
/// already owns — see docs/socket.md. Registered as a singleton (see
/// injection.dart) sharing that same [DriverSocketService] instance, and
/// resets itself whenever [DriverPresenceCubit] goes offline.
class DriverOrdersCubit extends Cubit<DriverOrdersState> {
  final DriverSocketService _socketService;
  final CurrentLocationService _location;
  late final StreamSubscription<DriverPresenceState> _presenceSubscription;

  DriverOrdersCubit(this._socketService, this._location, DriverPresenceCubit presenceCubit)
      : super(DriverOrdersState.initial()) {
    _socketService.setOrderListeners(
      onOrdersSnapshot: _handleSnapshot,
      onOrderOffer: _handleOffer,
      onOrderRemove: _handleRemove,
    );
    _presenceSubscription = presenceCubit.stream.listen((presenceState) {
      if (presenceState.status == DriverPresenceStatus.offline) {
        reset();
      }
    });
  }

  void _handleSnapshot(Map<String, dynamic> data) {
    final orders = ((data['orders'] as List?) ?? const [])
        .map((e) => OrderOfferModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (!isClosed) emit(state.copyWith(orders: orders));
  }

  void _handleOffer(Map<String, dynamic> data) {
    final order = OrderOfferModel.fromJson(data);
    final orders = [
      ...state.orders.where((o) => o.rideId != order.rideId),
      order,
    ];
    if (!isClosed) emit(state.copyWith(orders: orders));
  }

  void _handleRemove(Map<String, dynamic> data) {
    final rideId = data['ride_id'] as int;
    final orders = state.orders.where((o) => o.rideId != rideId).toList();
    if (!isClosed) {
      emit(state.copyWith(
        orders: orders,
        clearAccepting: state.acceptingRideId == rideId,
      ));
    }
  }

  /// Resolves once the server has answered the accept — [OrderAcceptResult.ok]
  /// on success, so the caller (the home screen) can navigate to the
  /// active-ride screen only when the driver actually won the ride. The
  /// result also carries the time to the pickup when the driver's position
  /// was known and sent with the accept.
  Future<OrderAcceptResult> acceptOrder(int rideId) async {
    if (state.acceptingRideId != null) return const OrderAcceptResult(ok: false);
    emit(state.copyWith(acceptingRideId: rideId, clearError: true));

    // Never holds the accept up for long: no fix in a moment means none.
    final position = await _location.quickPosition();
    final completer = Completer<OrderAcceptResult>();
    _socketService.acceptOrder(
      rideId: rideId,
      lat: position?.latitude,
      lng: position?.longitude,
      onResult: (result) {
        if (!isClosed) {
          // On success the card is removed via `driver:order_remove` — no
          // need to touch `orders` here. A refusal (a low wallet included)
          // leaves the card where it is: nothing was accepted.
          emit(state.copyWith(
            clearAccepting: true,
            errorMessage: result.ok
                ? null
                : (result.message ?? AppStrings.current.driverAcceptTripFailed),
            errorIsWalletTooLow: result.walletTooLow,
          ));
        }
        if (!completer.isCompleted) completer.complete(result);
      },
    );
    return completer.future;
  }

  void reset() {
    if (!isClosed) emit(DriverOrdersState.initial());
  }

  @override
  Future<void> close() {
    _presenceSubscription.cancel();
    return super.close();
  }
}
