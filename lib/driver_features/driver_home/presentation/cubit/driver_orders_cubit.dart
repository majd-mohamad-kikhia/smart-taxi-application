import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../data/datasources/driver_socket_service.dart';
import '../../data/datasources/new_order_alert.dart';
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
///
/// A ride that was not on the list yet sounds [NewOrderAlert] for 10 s. The
/// alert stops early once the driver taps accept, the list empties, or the
/// driver goes offline.
class DriverOrdersCubit extends Cubit<DriverOrdersState> {
  /// An offer whose turn ends this much later than the card on screen is a
  /// new wave of the same ride, not an update of the old one.
  static const _newWaveGap = Duration(seconds: 2);

  final DriverSocketService _socketService;
  final CurrentLocationService _location;
  final NewOrderAlert _alert;
  late final StreamSubscription<DriverPresenceState> _presenceSubscription;

  DriverOrdersCubit(
    this._socketService,
    this._location,
    DriverPresenceCubit presenceCubit,
    this._alert,
  )   : super(DriverOrdersState.initial()) {
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
    final isNew = _isNewOffer(order);
    final orders = [
      ...state.orders.where((o) => o.rideId != order.rideId),
      order,
    ];
    if (isClosed) return;
    emit(state.copyWith(orders: orders));
    if (isNew) _alert.start();
  }

  /// A ride not on the list yet, or one offered again in a later wave (its
  /// turn runs out later than the card already shown) — not a mere update.
  bool _isNewOffer(OrderOfferModel order) {
    final shown = state.orders.where((o) => o.rideId == order.rideId);
    if (shown.isEmpty) return true;
    final before = shown.first.expiresAt;
    final now = order.expiresAt;
    return before != null &&
        now != null &&
        now.difference(before) > _newWaveGap;
  }

  void _handleRemove(Map<String, dynamic> data) {
    final rideId = data['ride_id'] as int;
    final orders = state.orders.where((o) => o.rideId != rideId).toList();
    if (!isClosed) {
      emit(state.copyWith(
        orders: orders,
        clearAccepting: state.acceptingRideId == rideId,
      ));
      if (orders.isEmpty) _alert.stop();
    }
  }

  /// Resolves once the server has answered the accept — [OrderAcceptResult.ok]
  /// on success, so the caller (the home screen) can navigate to the
  /// active-ride screen only when the driver actually won the ride. The
  /// result also carries the time to the pickup when the driver's position
  /// was known and sent with the accept.
  Future<OrderAcceptResult> acceptOrder(int rideId) async {
    if (state.acceptingRideId != null) return const OrderAcceptResult(ok: false);
    // The driver has answered; the alert has done its job.
    _alert.stop();
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
          if (result.offerExpired || _turnIsOver(rideId, result)) {
            // The driver's turn ended while the tap was in flight: the card
            // goes quietly, with no error.
            _dropExpired(rideId);
          } else {
            // On success the card is removed via `driver:order_remove` — no
            // need to touch `orders` here. A refusal (a low wallet
            // included) leaves the card where it is: nothing was accepted.
            emit(state.copyWith(
              clearAccepting: true,
              errorMessage: result.ok
                  ? null
                  : (result.message ?? AppStrings.current.driverAcceptTripFailed),
              errorIsWalletTooLow: result.walletTooLow,
            ));
          }
        }
        if (!completer.isCompleted) completer.complete(result);
      },
    );
    return completer.future;
  }

  /// A refusal that isn't about the wallet, for a card whose countdown has
  /// already run out here — the server's wording may be in any language, so
  /// this catches what [OrderAcceptResult.offerExpired] can't read.
  bool _turnIsOver(int rideId, OrderAcceptResult result) {
    if (result.ok || result.walletTooLow) return false;
    final expiresAt = state.orders
        .where((o) => o.rideId == rideId)
        .map((o) => o.expiresAt)
        .firstOrNull;
    return expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc());
  }

  void _dropExpired(int rideId) {
    final orders = state.orders.where((o) => o.rideId != rideId).toList();
    emit(state.copyWith(orders: orders, clearAccepting: true));
    if (orders.isEmpty) _alert.stop();
  }

  void reset() {
    _alert.stop();
    if (!isClosed) emit(DriverOrdersState.initial());
  }

  @override
  Future<void> close() {
    _presenceSubscription.cancel();
    _alert.stop();
    return super.close();
  }
}
