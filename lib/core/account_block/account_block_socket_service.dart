import 'package:socket_io_client/socket_io_client.dart' as io;
import '../enums/user_role.dart';
import '../network/socket_client.dart';

/// Holds the always-on Socket.IO connection whose main job is the account
/// block feed: `customer:block_status` for customers,`driver:block_status`
/// for drivers. The server emits the current state once on every connect
/// (`action: snapshot`), then `blocked` / `unblocked` / `expired` as they
/// happen.
///
/// The same connection also carries `app:version_changed` (the manager
/// changed this app's versions or maintenance switch), which has no payload
/// worth reading — the app just asks the version check again.
///
/// Separate from the driver's presence socket and the customer's
/// ride-tracking socket because those only exist while online / on a ride,
/// whereas a block must show up on an idle app too.
class AccountBlockSocketService {
  static const String _appVersionChangedEvent = 'app:version_changed';

  io.Socket? _socket;
  bool _disposed = true;

  void connect({
    required String accessToken,
    required UserRole role,
    required void Function(Map<String, dynamic> data) onBlockStatus,
    required void Function() onAppVersionChanged,
  }) {
    disconnect();
    _disposed = false;

    final socket = createSocket(accessToken);
    socket.on(_eventFor(role), (data) {
      if (_disposed || data is! Map) return;
      onBlockStatus(Map<String, dynamic>.from(data));
    });
    socket.on(_appVersionChangedEvent, (_) {
      if (!_disposed) onAppVersionChanged();
    });
    socket.connect();
    _socket = socket;
  }

  static String _eventFor(UserRole role) => switch (role) {
    UserRole.customer => 'customer:block_status',
    UserRole.driver => 'driver:block_status',
  };

  void disconnect() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
  }
}
