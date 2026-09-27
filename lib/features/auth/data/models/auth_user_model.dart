import 'package:equatable/equatable.dart';
import '../../../../core/enums/user_role.dart';

/// The signed-in account, built from the API's `customer` + `tokens`
/// response objects (see `AuthSuccessData` in swagger.json).
class AuthUserModel extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String? address;
  final UserRole role;
  final String accessToken;
  final String refreshToken;

  const AuthUserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.photoUrl,
    this.address,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Builds an [AuthUserModel] from a signup/login response's `data`
  /// object, i.e. `{ "customer": {...}, "tokens": {...} }`.
  factory AuthUserModel.fromApiData(
    Map<String, dynamic> data, {
    required UserRole role,
  }) {
    final customer = data['customer'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    return AuthUserModel(
      id: customer['id'] as int,
      fullName: '${customer['first_name']} ${customer['last_name']}',
      phone: customer['phone_number'] as String,
      email: customer['email'] as String?,
      photoUrl: customer['photo_url'] as String?,
      address: customer['address'] as String?,
      role: role,
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        email,
        photoUrl,
        address,
        role,
        accessToken,
        refreshToken,
      ];
}
