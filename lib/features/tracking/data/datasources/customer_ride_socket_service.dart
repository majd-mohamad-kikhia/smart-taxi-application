import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/socket_client.dart';

/// Wraps the customer's live ride-tracking Socket.IO connection (see
/// docs/socket.md, "Customer ride tracking"). A fresh instance is created
/// per `RideTrackingCubit` — connected when the tracking screen opens and
/// disposed when it closes, unlike the driver side's long-lived shared
/// socket.
class CustomerRideSocketService {
  io.Socket? _socket;
  bool _disposed = true;

  void connect({
    required String accessToken,
    required void Function() onConnect,
    required void Function() onDisconnect,
    required void Function(dynamic error) onConnectError,
    required void Function(Map<String, dynamic> data) onRideAccepted,
    required void Function(Map<String, dynamic> data) onDriverLocation,
    required void Function(Map<String, dynamic> data) onRideStatus,
    required void Function(Map<String, dynamic>? data) onActiveRide,
    required void Function(Map<String, dynamic> data) onRidePaid,
  }) {
    disconnect();
    _disposed = false;

    final socket = createSocket(accessToken);
    socket.onConnect((_) {
      if (!_disposed) onConnect();
    });
    socket.onDisconnect((_) {
      if (!_disposed) onDisconnect();
    });
    socket.onConnectError((error) {
      if (!_disposed) onConnectError(error);
    });
    socket.on('customer:ride_accepted', (data) {
      if (!_disposed) onRideAccepted(Map<String, dynamic>.from(data as Map));
    });
    socket.on('customer:driver_location', (data) {
      if (!_disposed) onDriverLocation(Map<String, dynamic>.from(data as Map));
    });
    socket.on('customer:ride_status', (data) {
      if (!_disposed) onRideStatus(Map<String, dynamic>.from(data as Map));
    });
    socket.on('customer:ride_paid', (data) {
      if (!_disposed) onRidePaid(Map<String, dynamic>.from(data as Map));
    });
    socket.on('customer:active_ride', (data) {
      if (_disposed) return;
      final map = Map<String, dynamic>.from(data as Map);
      onActiveRide(map['ride'] == null ? null : map);
    });
    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
  }
}
