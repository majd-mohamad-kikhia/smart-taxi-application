import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../driver_auth/data/repositories/driver_repository.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'driver_settings_state.dart';

/// Drives the driver settings screen's search-radius slider. Reads the
/// signed-in driver's current radius from [DriverAuthCubit] (the single
/// owner of the driver profile) and saves through it, so a successful
/// save updates the shared driver state everywhere, not just this screen.
class DriverSettingsCubit extends Cubit<DriverSettingsState> {
  /// The slider's range. The API itself allows fractional values up to 100
  /// km; the product exposes this coarser range, so a stored radius outside
  /// it is shown at the nearest end.
  static const int minKm = 1;
  static const int maxKm = 10;

  final DriverAuthCubit _driverAuthCubit;

  DriverSettingsCubit(this._driverAuthCubit)
      : super(_initialState(_driverAuthCubit));

  static DriverSettingsState _initialState(DriverAuthCubit auth) {
    final km = (auth.state.driver?.searchRadiusKm ?? 1)
        .round()
        .clamp(minKm, maxKm);
    return DriverSettingsState(searchRadiusKm: km, savedSearchRadiusKm: km);
  }

  /// Moving the slider starts a new unsaved change, so the result of the
  /// last save no longer applies.
  void setSearchRadius(int km) {
    if (km == state.searchRadiusKm) return;
    emit(
      state.copyWith(
        searchRadiusKm: km,
        saveStatus: SearchRadiusSaveStatus.idle,
        clearError: true,
      ),
    );
  }

  Future<void> saveSearchRadius() async {
    if (state.saveStatus == SearchRadiusSaveStatus.saving) return;
    final km = state.searchRadiusKm;
    emit(
      state.copyWith(
        saveStatus: SearchRadiusSaveStatus.saving,
        clearError: true,
      ),
    );
    try {
      await _driverAuthCubit.updateSearchRadius(km.toDouble());
      if (isClosed) return;
      emit(
        state.copyWith(
          savedSearchRadiusKm: km,
          saveStatus: SearchRadiusSaveStatus.success,
        ),
      );
    } on DriverAuthException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          saveStatus: SearchRadiusSaveStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }
}
