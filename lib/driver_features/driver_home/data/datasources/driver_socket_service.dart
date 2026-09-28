import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/socket_client.dart';

/// Wraps the driver's live-location Socket.IO connection.
///
/// One instance per [DriverPresenceCubit] (see injection.dart) — never
/// touched directly by the UI. [_disposed] guards against a callback
/// firing after [disconnect] (the socket can emit its own `disconnect`
/// event asynchronously while being torn down).
class DriverSocketService {
  io.Socket? _socket;
  bool _disposed = true;

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
      if (!_disposed) onConnect();
    });
    socket.onDisconnect((_) {
      if (!_disposed) onDisconnect();
    });
    socket.onConnectError((error) {
      if (!_disposed) onConnectError(error);
    });
    socket.connect();
    _socket = socket;
  }

  void sendLocation({required double lat, required double lng}) {
    if (_disposed) return;
    _socket?.emit('driver:location', {'lat': lat, 'lng': lng});
  }

  void disconnect() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
  }
}
