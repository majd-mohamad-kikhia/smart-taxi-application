import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photoUrl;
  final bool isVerified;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.isVerified,
  });

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
    bool? isVerified,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, email, photoUrl, isVerified];
}
