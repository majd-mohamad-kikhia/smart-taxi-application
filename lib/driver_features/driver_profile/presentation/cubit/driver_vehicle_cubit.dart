import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../driver_auth/data/models/driver_vehicle_model.dart';
import '../../data/repositories/driver_vehicle_repository.dart';
import 'driver_vehicle_state.dart';

/// Drives the driver profile screen's vehicle card —
/// `GET /api/driver/vehicle`.
class DriverVehicleCubit extends Cubit<DriverVehicleState> {
  final DriverVehicleRepository _repository;

  DriverVehicleCubit(this._repository) : super(const DriverVehicleState());

  /// The server just returned the car in a reply of its own (a new car
  /// photo); show it without asking again.
  void replace(DriverVehicleModel vehicle) {
    if (isClosed || vehicle == state.vehicle) return;
    emit(state.copyWith(vehicle: vehicle, isLoading: false, clearError: true));
  }

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
