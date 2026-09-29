import 'package:equatable/equatable.dart';

/// The `vehicle` object pushed alongside a `customer:ride_accepted` /
/// `customer:active_ride` event (see docs/socket.md).
class RideVehicleModel extends Equatable {
  final int id;
  final String vehicleTypeName;
  final String brand;
  final String model;
  final String color;
  final String plateNumber;
  final String? photoUrl;

  const RideVehicleModel({
    required this.id,
    required this.vehicleTypeName,
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.photoUrl,
  });

  factory RideVehicleModel.fromJson(Map<String, dynamic> json) {
    return RideVehicleModel(
      id: (json['id'] as num).toInt(),
      vehicleTypeName: json['vehicle_type_name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }

  String get summary => '$brand $model • $color • $plateNumber';

  @override
  List<Object?> get props => [
        id,
        vehicleTypeName,
        brand,
        model,
        color,
        plateNumber,
        photoUrl,
      ];
}
