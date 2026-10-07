import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../driver_trip/data/datasources/open_trip_registry.dart';
import '../../../driver_trip/data/models/driver_active_ride_model.dart';
import '../../data/models/shared_order_preview_model.dart';
import '../../data/repositories/shared_order_repository.dart';
import 'shared_order_state.dart';

/// The order screen for an office order opened from its WhatsApp link
/// ([token]). Opening the link accepts it ([open]); first driver to accept
/// wins, and everyone else watching sees it close at once over the socket
/// (`driver:shared_order_closed`).
///
/// The preview call is what subscribes the socket to the order, and that
/// subscription is lost on reconnect — so the order is fetched again on
/// every socket connect, on app resume ([load] from the screen), when the
/// office edits it, and when a scheduled order opens. While the socket is
/// down (driver offline) it is polled instead.
class SharedOrderCubit extends Cubit<SharedOrderState> {
  static const _offlinePollInterval = Duration(seconds: 20);

  final SharedOrderRepository _repository;
  final OpenTripRegistry _openTrips;
  final bool Function() _isSocketConnected;
  final String token;

  late final List<StreamSubscription<dynamic>> _subscriptions;
  late final Timer _pollTimer;
  Timer? _opensAtTimer;

  /// The order's ride, once known — socket events are matched against it.
  int? _rideId;
  bool _isLoading = false;
  bool _reloadQueued = false;

  /// The accept sent by [open] has no answer yet.
  bool _openingAccept = false;

  SharedOrderCubit(
    this._repository,
    this._openTrips, {
    required this.token,
    required Stream<Map<String, dynamic>> orderClosed,
    required Stream<Map<String, dynamic>> orderUpdated,
    required Stream<void> socketConnected,
    required bool Function() isSocketConnected,
  }) : _isSocketConnected = isSocketConnected,
       super(const SharedOrderLoading()) {
    _subscriptions = [
      orderClosed.listen(_handleClosed),
      orderUpdated.listen(_handleUpdated),
      socketConnected.listen((_) => load()),
    ];
    _pollTimer = Timer.periodic(_offlinePollInterval, (_) {
      if (!_isSocketConnected() && state is SharedOrderLoaded) load();
    });
  }

  /// Opening the link takes the order at once: first driver wins, so the
  /// accept goes out before any preview. When it is refused, the order is
  /// fetched and shown with the reason (a low wallet: with the server's
  /// message); when it got no answer, it is tried once more after that
  /// fetch.
  Future<void> open() async {
    final current = state;
    if (isClosed || _openingAccept) return;
    if (current is! SharedOrderLoading && current is! SharedOrderFailure) return;
    if (current is SharedOrderFailure) emit(const SharedOrderLoading());
    _openingAccept = true;
    SharedOrderException? refusal;
    DriverActiveRideModel? ride;
    try {
      ride = await _repository.accept(token);
    } on SharedOrderException catch (e) {
      refusal = e;
    } finally {
      _openingAccept = false;
    }
    if (isClosed) return;
    if (refusal == null) {
      _showAccepted(ride);
    } else if (refusal.isInvalidLink) {
      emit(const SharedOrderInvalidLink());
    } else {
      await load();
      final loaded = state;
      if (refusal.walletTooLow) {
        if (loaded is SharedOrderLoaded) {
          emit(loaded.copyWith(walletMessage: refusal.message));
        }
      } else if (refusal.isNetwork) {
        await accept();
      }
    }
  }

  /// Fetches the order. The first call shows a spinner; later ones refresh
  /// what is on screen quietly and keep it when they fail.
  Future<void> load() async {
    if (isClosed || _isFinal(state) || _isAccepting) return;
    final current = state;
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }
    _isLoading = true;
    if (current is! SharedOrderLoaded) emit(const SharedOrderLoading());
    try {
      final preview = await _repository.preview(token);
      if (!isClosed && !_isFinal(state) && !_isAccepting) await _show(preview);
    } on SharedOrderException catch (e) {
      if (isClosed || _isFinal(state) || _isAccepting) return;
      if (e.isInvalidLink) {
        emit(const SharedOrderInvalidLink());
      } else if (state is! SharedOrderLoaded) {
        emit(SharedOrderFailure(e.message));
      }
    } finally {
      _isLoading = false;
      if (_reloadQueued && !isClosed) {
        _reloadQueued = false;
        load();
      }
    }
  }

  /// Takes the order. Safe to retry: asking again for an order this driver
  /// already has returns the same ride.
  Future<void> accept() async {
    final current = state;
    if (current is! SharedOrderLoaded || current.accepting || !current.preview.canAccept) {
      return;
    }
    emit(current.copyWith(accepting: true));
    await _take(current.preview);
  }

  Future<void> _show(SharedOrderPreviewModel preview) async {
    _rideId = preview.rideId;
    _scheduleOpening(preview);
    if (preview.availability.isClosed) {
      emit(SharedOrderClosed(preview.availability, preview: preview));
    } else if (preview.availability == SharedOrderAvailability.yours) {
      await _openOwnTrip(preview);
    } else {
      emit(SharedOrderLoaded(preview, hasOpenTrip: _openTrips.openRideId != null));
    }
  }

  /// The order is already this driver's (accepted here a moment ago, or on
  /// another device): back to its trip screen if open, else open it.
  Future<void> _openOwnTrip(SharedOrderPreviewModel? preview) async {
    if (_openTrips.openRideId == _rideId) {
      emit(const SharedOrderBackToTrip());
      return;
    }
    await _take(preview);
  }

  Future<void> _take(SharedOrderPreviewModel? preview) async {
    try {
      final ride = await _repository.accept(token);
      if (!isClosed) _showAccepted(ride);
    } on SharedOrderException catch (e) {
      if (isClosed) return;
      final availability = e.availability;
      if (e.isInvalidLink) {
        emit(const SharedOrderInvalidLink());
      } else if (availability == SharedOrderAvailability.yours) {
        emit(const SharedOrderBackToTrip());
      } else if (e.walletTooLow && preview != null) {
        // Not taken by anyone: the order stays open to accept after a top-up.
        emit(SharedOrderLoaded(
          preview,
          walletMessage: e.message,
          hasOpenTrip: _openTrips.openRideId != null,
        ));
      } else if (availability != null && preview != null) {
        await _show(preview.withAvailability(availability, opensAt: e.opensAt));
      } else if (availability != null && availability.isClosed) {
        emit(SharedOrderClosed(availability));
      } else if (preview != null) {
        emit(SharedOrderLoaded(
          preview,
          acceptError: e.message,
          hasOpenTrip: _openTrips.openRideId != null,
        ));
      } else {
        emit(SharedOrderFailure(e.message));
      }
    }
  }

  void _showAccepted(DriverActiveRideModel? ride) {
    // An in-progress trip needs the route recorded on the device it
    // started on; it can't be opened from a link. Accepting again returns
    // the same ride, so its trip screen may already be open.
    if (ride == null || ride.isInProgress || _openTrips.openRideId == ride.order.rideId) {
      emit(const SharedOrderBackToTrip());
      return;
    }
    _openTrips.open(ride.order.rideId);
    emit(SharedOrderAccepted(ride));
  }

  void _handleClosed(Map<String, dynamic> json) {
    // While our own accept is in flight, its answer decides.
    if (!_isAboutThisOrder(json) || _isFinal(state) || _isAccepting) return;
    final current = state;
    final preview = current is SharedOrderLoaded ? current.preview : null;
    if (json['taken_by_you'] == true) {
      _openOwnTrip(preview);
      return;
    }
    final reason = SharedOrderAvailability.fromWire(json['reason']);
    emit(SharedOrderClosed(
      reason == SharedOrderAvailability.cancelled
          ? SharedOrderAvailability.cancelled
          : SharedOrderAvailability.taken,
      preview: preview,
    ));
  }

  void _handleUpdated(Map<String, dynamic> json) {
    if (_isAboutThisOrder(json)) load();
  }

  bool _isAboutThisOrder(Map<String, dynamic> json) {
    final rideId = (json['ride_id'] as num?)?.toInt();
    return rideId != null && rideId == _rideId;
  }

  /// A scheduled order opens at `opens_at`: fetch it again then.
  void _scheduleOpening(SharedOrderPreviewModel preview) {
    _opensAtTimer?.cancel();
    final opensAt = preview.opensAt;
    if (preview.availability != SharedOrderAvailability.scheduled || opensAt == null) {
      return;
    }
    var delay = opensAt.difference(DateTime.now().toUtc()) + const Duration(seconds: 1);
    if (delay.isNegative) delay = const Duration(seconds: 5);
    _opensAtTimer = Timer(delay, load);
  }

  bool get _isAccepting {
    final current = state;
    return _openingAccept || (current is SharedOrderLoaded && current.accepting);
  }

  static bool _isFinal(SharedOrderState state) =>
      state is SharedOrderClosed ||
      state is SharedOrderAccepted ||
      state is SharedOrderBackToTrip ||
      state is SharedOrderInvalidLink;

  @override
  Future<void> close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _pollTimer.cancel();
    _opensAtTimer?.cancel();
    return super.close();
  }
}
