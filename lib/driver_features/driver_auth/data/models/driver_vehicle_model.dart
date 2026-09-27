import 'package:equatable/equatable.dart';

/// A driver's registered vehicle — mirrors `DriverVehicle` in
/// swagger.json.
class DriverVehicleModel extends Equatable {
  final int id;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final String brand;
  final String model;
  final String color;
  final String plateNumber;
  final String? photoUrl;

  const DriverVehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.photoUrl,
  });

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    return DriverVehicleModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicle_type_id'] as int,
      vehicleTypeName: json['vehicle_type_name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
      plateNumber: json['plate_number'] as String,
      photoUrl: json['photo_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleTypeId,
        vehicleTypeName,
        brand,
        model,
        color,
        plateNumber,
        photoUrl,
      ];
}
