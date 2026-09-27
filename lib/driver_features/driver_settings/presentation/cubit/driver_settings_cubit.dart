import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../driver_auth/data/repositories/driver_repository.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'driver_settings_state.dart';

/// Drives the driver settings screen's search-radius slider. Reads the
/// signed-in driver's current radius from [DriverAuthCubit] (the single
/// owner of the driver profile) and saves through it, so a successful
/// save updates the shared driver state everywhere, not just this screen.
class DriverSettingsCubit extends Cubit<DriverSettingsState> {
  final DriverAuthCubit _driverAuthCubit;

  DriverSettingsCubit(this._driverAuthCubit)
      : super(
          DriverSettingsState(
            searchRadiusKm:
                (_driverAuthCubit.state.driver?.searchRadiusKm ?? 1).round(),
          ),
        );

  void setSearchRadius(int km) {
    if (km == state.searchRadiusKm) return;
    emit(state.copyWith(searchRadiusKm: km, clearError: true));
  }

  Future<void> saveSearchRadius() async {
    emit(
      state.copyWith(
        saveStatus: SearchRadiusSaveStatus.saving,
        clearError: true,
      ),
    );
    try {
      await _driverAuthCubit.updateSearchRadius(state.searchRadiusKm.toDouble());
      if (isClosed) return;
      emit(state.copyWith(saveStatus: SearchRadiusSaveStatus.success));
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
