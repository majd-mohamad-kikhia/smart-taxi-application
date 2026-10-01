import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/gps_status_service.dart';
import 'gps_status_state.dart';

/// Tracks whether the phone's GPS is on, for the driver app's "turn on
/// location" dialog. A singleton (see injection.dart): every driver screen
/// that is guarded shares this one connection to the system's status.
///
/// It follows the system's on/off events and can also be re-checked on
/// demand — e.g. when the driver comes back from the settings page.
class GpsStatusCubit extends Cubit<GpsStatusState> {
  final GpsStatusService _service;
  StreamSubscription<bool>? _subscription;
  bool _started = false;

  GpsStatusCubit(this._service) : super(const GpsStatusState());

  /// Starts following the GPS switch. Safe to call again — it only starts
  /// once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = _service.statusStream().listen(
      _set,
      onError: (Object error) =>
          debugPrint('GpsStatusCubit: status stream error: $error'),
    );
    await recheck();
  }

  /// Asks the system right now. Covers the cases where no event fired.
  Future<void> recheck() async {
    try {
      _set(await _service.isEnabled());
    } catch (e) {
      // Can't tell: leave the state as it is rather than block the driver.
      debugPrint('GpsStatusCubit: could not read the GPS status: $e');
    }
  }

  Future<void> openSettings() async {
    try {
      await _service.openSettings();
    } catch (e) {
      debugPrint('GpsStatusCubit: could not open location settings: $e');
    }
  }

  void _set(bool enabled) {
    if (!isClosed) emit(GpsStatusState(isEnabled: enabled));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
