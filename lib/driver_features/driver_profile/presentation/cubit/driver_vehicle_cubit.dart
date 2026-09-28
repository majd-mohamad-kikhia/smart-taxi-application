import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/driver_vehicle_repository.dart';
import 'driver_vehicle_state.dart';

/// Drives the driver profile screen's vehicle card —
/// `GET /api/driver/vehicle`.
class DriverVehicleCubit extends Cubit<DriverVehicleState> {
  final DriverVehicleRepository _repository;

  DriverVehicleCubit(this._repository) : super(const DriverVehicleState());

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final vehicle = await _repository.getVehicle();
      if (isClosed) return;
      emit(state.copyWith(vehicle: vehicle, isLoading: false));
    } on DriverVehicleException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }
}
