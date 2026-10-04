import 'package:equatable/equatable.dart';

/// Who owns the driver's car — `vehicle.ownership` in swagger.
enum VehicleOwnership {
  owner('owner'),
  company('company');

  final String wireValue;

  const VehicleOwnership(this.wireValue);

  /// Null for a car registered before the field existed.
  static VehicleOwnership? fromWire(Object? value) {
    for (final ownership in values) {
      if (ownership.wireValue == value) return ownership;
    }
    return null;
  }
}

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
  final VehicleOwnership? ownership;

  const DriverVehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.photoUrl,
    this.ownership,
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
      ownership: VehicleOwnership.fromWire(json['ownership']),
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
        ownership,
      ];
}
