import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../../../core/services/current_location_service.dart';
import '../../../../core/services/google_routes_service.dart';
import '../../../../core/services/route_exception.dart';
import '../../data/location_ticker.dart';
import 'driver_home_map_state.dart';
import 'driver_orders_cubit.dart';

/// Feeds the driver's home map: the driver's own position (from the same GPS
/// fixes that are sent to the server while online, or the phone's last known
/// one before that) and the road of the offer being looked at, from its
/// pickup to its drop-off, fetched from Google Routes once per offer.
class DriverHomeMapCubit extends Cubit<DriverHomeMapState> {
  final LocationTicker _ticker;
  final CurrentLocationService _location;
  final DriverOrdersCubit _orders;
  final GoogleRoutesService _routes;

  late final StreamSubscription<Position> _positionSub;
  late final StreamSubscription<OrderOfferModel?> _selectionSub;

  /// Roads already fetched, by ride, so flipping between offers costs nothing.
  final Map<int, List<RoutePointModel>> _routeCache = {};

  /// The ride whose road the map wants right now, so a slow answer for an
  /// offer the driver has moved on from is dropped.
  int? _wantedRide;

  DriverHomeMapCubit(this._ticker, this._location, this._orders, this._routes)
    : super(const DriverHomeMapState()) {
    final known = _ticker.lastPosition;
    if (known != null) _showDriverAt(known);
    _positionSub = _ticker.positions.listen(_showDriverAt);
    _selectionSub = _orders.stream
        .map((state) => state.selectedOrder)
        .distinct()
        .listen(_onSelected);
    _onSelected(_orders.state.selectedOrder);
    unawaited(_seedPosition());
  }

  /// Before the first live fix (the driver is not online yet) the phone's
  /// last known position puts the map where the driver is. Never asks for
  /// the permission: going online does.
  Future<void> _seedPosition() async {
    if (state.hasDriverPosition) return;
    final position = await _location.getPositionIfAllowed();
    if (isClosed || position == null || state.hasDriverPosition) return;
    _showDriverAt(position);
  }

  void _showDriverAt(Position position) {
    if (isClosed) return;
    emit(
      state.copyWith(
        driverLat: position.latitude,
        driverLng: position.longitude,
      ),
    );
  }

  void _onSelected(OrderOfferModel? order) {
    if (isClosed) return;
    if (order == null) {
      _wantedRide = null;
      emit(state.copyWith(clearRoute: true));
      return;
    }
    _wantedRide = order.rideId;
    final cached = _routeCache[order.rideId];
    emit(
      state.copyWith(routeRideId: order.rideId, orderRoute: cached ?? const []),
    );
    if (cached == null) unawaited(_loadRoute(order));
  }

  Future<void> _loadRoute(OrderOfferModel order) async {
    try {
      final route = await _routes.computeRoute(
        fromLat: order.pickupLat,
        fromLng: order.pickupLng,
        toLat: order.dropoffLat,
        toLng: order.dropoffLng,
      );
      _routeCache[order.rideId] = route.points;
      if (isClosed || _wantedRide != order.rideId) return;
      emit(state.copyWith(orderRoute: route.points));
    } on RouteException catch (e) {
      // The map keeps its straight dashed line; the card has the details.
      debugPrint('DriverHomeMapCubit: no road for ride ${order.rideId}: $e');
    }
  }

  @override
  Future<void> close() async {
    await _positionSub.cancel();
    await _selectionSub.cancel();
    return super.close();
  }
}
