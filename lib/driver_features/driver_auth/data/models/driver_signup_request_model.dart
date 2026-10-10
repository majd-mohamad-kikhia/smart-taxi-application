import 'package:equatable/equatable.dart';

/// Who owns the car (`vehicle_ownership`).
enum VehicleOwnership {
  owner,
  company;

  String get wireValue => name;
}

/// One car type the driver can sign up with, from
/// `GET /api/driver/auth/vehicle-types` (active types only). The [name] is
/// the manager's and is shown as it is.
class SignupVehicleType extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int? maxPassengers;

  const SignupVehicleType({
    required this.id,
    required this.name,
    this.description,
    this.maxPassengers,
  });

  factory SignupVehicleType.fromJson(Map<String, dynamic> json) => SignupVehicleType(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    maxPassengers: (json['max_passengers'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [id, name, description, maxPassengers];
}

/// Everything `POST /api/driver/auth/signup` takes (multipart): the account,
/// the car and the two photos (file paths).
class DriverSignupRequestModel extends Equatable {
  final String firstName;
  final String lastName;
  final String phone;
  final String password;
  final String? address;
  final int vehicleTypeId;
  final String brand;
  final String model;
  final String color;
  final String plateNumber;
  final VehicleOwnership ownership;
  final String photoPath;
  final String vehiclePhotoPath;

  const DriverSignupRequestModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.password,
    this.address,
    required this.vehicleTypeId,
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
    required this.ownership,
    required this.photoPath,
    required this.vehiclePhotoPath,
  });

  /// The text parts of the form. The phone stays text so a leading `0` is
  /// kept.
  Map<String, String> toFields() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phone,
    'password': password,
    if (address != null && address!.isNotEmpty) 'address': address!,
    'vehicle_type_id': '$vehicleTypeId',
    'brand': brand,
    'model': model,
    'color': color,
    'plate_number': plateNumber,
    'vehicle_ownership': ownership.wireValue,
  };

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    phone,
    password,
    address,
    vehicleTypeId,
    brand,
    model,
    color,
    plateNumber,
    ownership,
    photoPath,
    vehiclePhotoPath,
  ];
}
