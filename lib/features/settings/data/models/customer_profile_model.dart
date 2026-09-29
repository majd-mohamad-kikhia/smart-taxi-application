import 'package:equatable/equatable.dart';

/// Customer profile as returned by `/api/customer/profile` (`Customer`
/// schema in swagger.json).
class CustomerProfileModel extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? address;
  final String? photoUrl;

  const CustomerProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.address,
    this.photoUrl,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone_number'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    phone,
    email,
    address,
    photoUrl,
  ];
}
