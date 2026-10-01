import 'package:equatable/equatable.dart';
import '../../../driver_auth/data/models/driver_vehicle_model.dart';

class DriverVehicleState extends Equatable {
  final DriverVehicleModel? vehicle;
  final bool isLoading;
  final String? errorMessage;

  const DriverVehicleState({
    this.vehicle,
    this.isLoading = true,
    this.errorMessage,
  });

  DriverVehicleState copyWith({
    DriverVehicleModel? vehicle,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverVehicleState(
      vehicle: vehicle ?? this.vehicle,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [vehicle, isLoading, errorMessage];
}
