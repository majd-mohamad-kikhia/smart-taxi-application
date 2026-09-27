import 'package:equatable/equatable.dart';
import '../enums/user_role.dart';

/// The currently signed-in account's basic profile — read by any feature
/// that needs to display "who is logged in" (Settings' profile card,
/// Home's greeting, etc.) via [SessionCubit].
class AppUser extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.role,
  });

  /// First token of [fullName] — for short greetings ("صباح الخير يا أحمد").
  String get firstName => fullName.split(' ').first;

  @override
  List<Object?> get props => [id, fullName, phone, email, photoUrl, role];
}
