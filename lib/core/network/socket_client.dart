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
        // Never give up: after a server restart or a lost connection the
        // app must come back by itself. Back-off from 1 s up to 10 s.
        .setReconnectionAttempts(1 << 30)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(10000)
        .setAuth({'token': accessToken})
        .disableAutoConnect()
        .build(),
  );
}
