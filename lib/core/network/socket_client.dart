import 'package:socket_io_client/socket_io_client.dart' as io;

const String _socketUrl = 'https://smart-taxi.ma-core.net';

/// Creates a Socket.IO client authenticated with [accessToken] (the same
/// JWT used for REST calls — driver or manager, never a customer token).
/// The caller still has to call `.connect()` and register listeners.
io.Socket createSocket(String accessToken) {
  return io.io(
    _socketUrl,
    io.OptionBuilder()
        .setPath('/socket.io/')
        .setTransports(['websocket'])
        .enableReconnection()
        .setReconnectionAttempts(20)
        .setReconnectionDelay(1000)
        .setAuth({'token': accessToken})
        .disableAutoConnect()
        .build(),
  );
}
