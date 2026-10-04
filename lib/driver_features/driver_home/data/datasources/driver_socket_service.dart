import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/socket_client.dart';

/// Wraps the driver's live-location + ride-offers Socket.IO connection.
///
/// One instance per app session (registered as a lazy singleton — see
/// injection.dart) so [DriverPresenceCubit] and `DriverOrdersCubit` share
/// the same connection instead of opening two sockets. [_disposed] guards
/// against a callback firing after [disconnect] (the socket can emit its
/// own `disconnect` event asynchronously while being torn down).
///
/// Order-event callbacks are stored via [setOrderListeners] and
/// re-attached to the socket on every [connect] call, since [connect]
/// always creates a fresh `io.Socket` instance.
class DriverSocketService {
  io.Socket? _socket;
  bool _disposed = true;

  /// `driver:ride_cancelled` payloads. A broadcast stream rather than a
  /// single callback, because each trip screen's cubit subscribes for as
  /// long as its ride is open; it outlives every [connect].
  final _rideCancelled = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rideCancelled => _rideCancelled.stream;

  /// `driver:active_ride` payloads: the driver's current ride, pushed on
  /// every connect, when the office assigns a trip to this driver, and when
  /// the office edits it (`details_updated: true`).
  final _activeRide = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get activeRide => _activeRide.stream;

  /// Office orders opened from their WhatsApp link: the socket is
  /// subscribed to one by its preview call, and loses that on reconnect.
  /// `driver:shared_order_closed` = taken / cancelled,
  /// `driver:shared_order_updated` = edited or just opened (re-fetch it).
  final _sharedOrderClosed = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sharedOrderClosed => _sharedOrderClosed.stream;
  final _sharedOrderUpdated = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sharedOrderUpdated => _sharedOrderUpdated.stream;

  /// Fires on every (re)connect — subscriptions made over REST must be
  /// renewed then.
  final _connected = StreamController<void>.broadcast();
  Stream<void> get connected => _connected.stream;

  bool get isConnected => !_disposed && (_socket?.connected ?? false);

  void Function(Map<String, dynamic> data)? _onOrdersSnapshot;
  void Function(Map<String, dynamic> data)? _onOrderOffer;
  void Function(Map<String, dynamic> data)? _onOrderRemove;

  /// Registers the callbacks used to feed the driver's order-cards state.
  /// Safe to call before the first [connect].
  void setOrderListeners({
    required void Function(Map<String, dynamic> data) onOrdersSnapshot,
    required void Function(Map<String, dynamic> data) onOrderOffer,
    required void Function(Map<String, dynamic> data) onOrderRemove,
  }) {
    _onOrdersSnapshot = onOrdersSnapshot;
    _onOrderOffer = onOrderOffer;
    _onOrderRemove = onOrderRemove;
  }

  void connect({
    required String accessToken,
    required void Function() onConnect,
    required void Function() onDisconnect,
    required void Function(dynamic error) onConnectError,
  }) {
    disconnect();
    _disposed = false;

    final socket = createSocket(accessToken);
    socket.onConnect((_) {
      if (_disposed) return;
      onConnect();
      _connected.add(null);
    });
    socket.onDisconnect((_) {
      if (!_disposed) onDisconnect();
    });
    socket.onConnectError((error) {
      if (!_disposed) onConnectError(error);
    });
    socket.on('driver:orders_snapshot', (data) {
      if (!_disposed) {
        _onOrdersSnapshot?.call(Map<String, dynamic>.from(data as Map));
      }
    });
    socket.on('driver:order_offer', (data) {
      if (!_disposed) {
        _onOrderOffer?.call(Map<String, dynamic>.from(data as Map));
      }
    });
    socket.on('driver:order_remove', (data) {
      if (!_disposed) {
        _onOrderRemove?.call(Map<String, dynamic>.from(data as Map));
      }
    });
    socket.on('driver:ride_cancelled', (data) {
      if (!_disposed) {
        _rideCancelled.add(Map<String, dynamic>.from(data as Map));
      }
    });
    socket.on('driver:active_ride', (data) {
      if (!_disposed && data is Map) {
        _activeRide.add(Map<String, dynamic>.from(data));
      }
    });
    socket.on('driver:shared_order_closed', (data) {
      if (!_disposed && data is Map) {
        _sharedOrderClosed.add(Map<String, dynamic>.from(data));
      }
    });
    socket.on('driver:shared_order_updated', (data) {
      if (!_disposed && data is Map) {
        _sharedOrderUpdated.add(Map<String, dynamic>.from(data));
      }
    });
    socket.connect();
    _socket = socket;
  }

  void sendLocation({required double lat, required double lng}) {
    if (_disposed) return;
    _socket?.emit('driver:location', {'lat': lat, 'lng': lng});
  }

  /// Accepts a ride offer via the ack-based `driver:order_accept` event
  /// (preferred over the REST `POST /api/driver/rides/:id/accept` — same
  /// atomic compare-and-set on the server either way). [onResult] receives
  /// `ok` and, on failure, the server's `error` message.
  void acceptOrder({
    required int rideId,
    required void Function(bool ok, String? error) onResult,
  }) {
    if (_disposed || _socket == null) {
      onResult(false, AppStrings.current.errNotConnected);
      return;
    }
    _socket!.emitWithAck(
      'driver:order_accept',
      {'ride_id': rideId},
      ack: (res) {
        final map = Map<String, dynamic>.from(res as Map);
        onResult(map['ok'] == true, map['error'] as String?);
      },
    );
  }

  void disconnect() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
  }
}
