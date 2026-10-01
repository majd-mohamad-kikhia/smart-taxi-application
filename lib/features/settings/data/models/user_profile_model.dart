import 'package:equatable/equatable.dart';

/// The customer's name, contact details and photo as the settings card
/// shows them. It carries only what the account really has: there is no
/// "verified" flag, so none is shown.
class UserProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photoUrl;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.photoUrl,
  });

  /// Nothing known yet (no signed-in customer): the card shows blanks, never
  /// someone else's details.
  const UserProfileModel.empty()
      : id = '',
        fullName = '',
        phone = '',
        email = '',
        photoUrl = null;

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, email, photoUrl];
}
