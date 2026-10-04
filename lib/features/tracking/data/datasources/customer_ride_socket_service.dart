import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/localization/app_strings.dart';
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
    required void Function(Map<String, dynamic> data) onRidePauseUpdate,
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
    socket.on('customer:ride_pause_update', (data) {
      if (!_disposed) onRidePauseUpdate(Map<String, dynamic>.from(data as Map));
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

  /// Cancels the order via the ack-based `customer:ride_cancel` event
  /// (faster than REST `POST /api/customer/rides/:id/cancel`, same rules —
  /// allowed while requested/accepted/arrived). Retries are safe: cancelling
  /// an already-cancelled ride returns `ok: true`. [onResult] receives `ok`,
  /// on failure the server's `error` message, and on success the cancelled
  /// `ride` (with its `cancel_penalty`).
  void cancelRide({
    required int rideId,
    String? cancellationReason,
    required void Function(bool ok, String? error, Map<String, dynamic>? ride) onResult,
  }) {
    final socket = _socket;
    if (_disposed || socket == null || !socket.connected) {
      onResult(false, AppStrings.current.errNotConnected, null);
      return;
    }
    socket.emitWithAck(
      'customer:ride_cancel',
      {
        'ride_id': rideId,
        'cancellation_reason': ?cancellationReason,
      },
      ack: (res) {
        final map = Map<String, dynamic>.from(res as Map);
        final ride = map['ride'];
        onResult(
          map['ok'] == true,
          map['error'] as String?,
          ride is Map ? Map<String, dynamic>.from(ride) : null,
        );
      },
    );
  }

  void disconnect() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
  }
}
