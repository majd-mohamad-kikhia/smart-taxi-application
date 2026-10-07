import 'package:equatable/equatable.dart';

/// The driver's own car — `DriverVehicle` in swagger — as far as the trip
/// needs it: what the customer looks for at pickup.
class DriverTripVehicleModel extends Equatable {
  final String brand;
  final String model;
  final String color;
  final String plateNumber;

  const DriverTripVehicleModel({
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
  });

  factory DriverTripVehicleModel.fromJson(Map<String, dynamic> json) {
    return DriverTripVehicleModel(
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [brand, model, color, plateNumber];
}
