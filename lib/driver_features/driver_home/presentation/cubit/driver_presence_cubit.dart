import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/driver_socket_service.dart';
import '../../data/location_ticker.dart';
import 'driver_presence_state.dart';

/// Drives the driver's online/offline toggle.
///
/// Going online starts [LocationTicker] and connects [DriverSocketService]
/// with the current [ApiClient.authToken]; either one failing tears both
/// back down. A connection that doesn't come up within [_connectTimeout]
/// (the socket neither connected nor reported an error, or the server
/// dropped it without a reconnect) is retried on a fresh socket, and
/// reported as an error once [_maxConnectAttempts] are used up, so the
/// toggle never sits on "Connecting…" forever. Registered as a singleton
/// (see injection.dart) so the connection survives tab switches in
/// `DriverMainWrapperScreen`'s `IndexedStack`, and is explicitly stopped on
/// logout.
class DriverPresenceCubit extends Cubit<DriverPresenceState> {
  static const _connectTimeout = Duration(seconds: 8);
  static const _maxConnectAttempts = 3;

  final DriverSocketService _socketService;
  final LocationTicker _locationTicker;
  Timer? _connectWatchdog;
  int _connectAttempts = 0;

  DriverPresenceCubit(this._socketService, this._locationTicker)
      : super(DriverPresenceState.initial());

  Future<void> goOnline() async {
    if (state.status == DriverPresenceStatus.online ||
        state.status == DriverPresenceStatus.connecting) {
      return;
    }
    final token = ApiClient.authToken;
    if (token == null) return;

    emit(state.copyWith(status: DriverPresenceStatus.connecting, clearError: true));

    try {
      await _locationTicker.start(
        (position) => _socketService.sendLocation(
          lat: position.latitude,
          lng: position.longitude,
        ),
      );
    } on LocationPermissionDeniedException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: DriverPresenceStatus.error,
          locationFailureReason: e.reason,
          errorMessage: switch (e.reason) {
            LocationFailureReason.serviceDisabled =>
              AppStrings.current.errEnableGps,
            LocationFailureReason.permissionDenied =>
              AppStrings.current.errEnableLocationPermission,
          },
        ));
      }
      return;
    } catch (e, stack) {
      // Anything else from the platform (a permission request already in
      // flight, a foreground service that wouldn't start…) must not leave
      // the toggle on "Connecting…".
      debugPrint('DriverPresenceCubit: could not start location updates: $e\n$stack');
      await _tearDown();
      if (!isClosed) {
        emit(state.copyWith(
          status: DriverPresenceStatus.error,
          errorMessage: AppStrings.current.errUnexpected,
        ));
      }
      return;
    }

    // Offline was tapped while the permission prompt was open.
    if (isClosed || state.status != DriverPresenceStatus.connecting) {
      await _locationTicker.stop();
      return;
    }

    _connectAttempts = 0;
    _connectSocket(token);
  }

  void _connectSocket(String token) {
    _connectAttempts++;
    _armConnectWatchdog(token);
    _socketService.connect(
      accessToken: token,
      onConnect: () {
        _connectWatchdog?.cancel();
        _connectAttempts = 0;
        // The server lists the driver as available once it has a location.
        _locationTicker.resend();
        if (!isClosed) {
          emit(state.copyWith(status: DriverPresenceStatus.online, clearError: true));
        }
      },
      onDisconnect: () {
        if (isClosed) return;
        emit(state.copyWith(status: DriverPresenceStatus.connecting));
        // A server-side disconnect isn't retried by socket.io itself.
        _connectAttempts = 0;
        _armConnectWatchdog(token);
      },
      onConnectError: (_) {
        _connectWatchdog?.cancel();
        if (!isClosed) {
          emit(state.copyWith(
            status: DriverPresenceStatus.error,
            errorMessage: AppStrings.current.errServerUnreachable,
          ));
        }
      },
    );
  }

  void _armConnectWatchdog(String token) {
    _connectWatchdog?.cancel();
    _connectWatchdog = Timer(_connectTimeout, () async {
      if (isClosed || state.status != DriverPresenceStatus.connecting) return;
      if (_connectAttempts >= _maxConnectAttempts) {
        await _tearDown();
        if (!isClosed) {
          emit(state.copyWith(
            status: DriverPresenceStatus.error,
            errorMessage: AppStrings.current.errServerUnreachable,
          ));
        }
        return;
      }
      debugPrint('DriverPresenceCubit: still connecting, retrying on a fresh socket');
      _connectSocket(ApiClient.authToken ?? token);
    });
  }

  Future<void> _tearDown() async {
    _connectWatchdog?.cancel();
    await _locationTicker.stop();
    _socketService.disconnect();
  }

  Future<void> goOffline() async {
    await _tearDown();
    if (!isClosed) emit(DriverPresenceState.initial());
  }

  @override
  Future<void> close() {
    _tearDown();
    return super.close();
  }
}
