import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/driver_socket_service.dart';
import '../../data/location_ticker.dart';
import 'driver_presence_state.dart';

/// Drives the driver's online/offline toggle.
///
/// Going online starts [LocationTicker] and connects [DriverSocketService]
/// with the current [ApiClient.authToken]; either one failing tears both
/// back down. Registered as a singleton (see injection.dart) so the
/// connection survives tab switches in `DriverMainWrapperScreen`'s
/// `IndexedStack`, and is explicitly stopped on logout.
class DriverPresenceCubit extends Cubit<DriverPresenceState> {
  final DriverSocketService _socketService;
  final LocationTicker _locationTicker;

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
              'يرجى تفعيل خدمة الموقع (GPS) في إعدادات الجهاز',
            LocationFailureReason.permissionDenied =>
              'يرجى تفعيل صلاحية الموقع للتطبيق من إعدادات الجهاز',
          },
        ));
      }
      return;
    }

    _socketService.connect(
      accessToken: token,
      onConnect: () {
        if (!isClosed) {
          emit(state.copyWith(status: DriverPresenceStatus.online, clearError: true));
        }
      },
      onDisconnect: () {
        if (!isClosed) emit(state.copyWith(status: DriverPresenceStatus.connecting));
      },
      onConnectError: (_) {
        if (!isClosed) {
          emit(state.copyWith(
            status: DriverPresenceStatus.error,
            errorMessage: 'تعذر الاتصال بالخادم',
          ));
        }
      },
    );
  }

  Future<void> goOffline() async {
    await _locationTicker.stop();
    _socketService.disconnect();
    if (!isClosed) emit(DriverPresenceState.initial());
  }

  @override
  Future<void> close() {
    _locationTicker.stop();
    _socketService.disconnect();
    return super.close();
  }
}
