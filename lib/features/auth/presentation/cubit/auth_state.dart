import 'package:equatable/equatable.dart';
import '../../../../core/enums/user_role.dart';
import '../../data/models/auth_user_model.dart';

enum AuthStatus { idle, submitting, success, failure }

/// Immutable state for the auth flow (role selection → sign in / sign up).
class AuthState extends Equatable {
  final UserRole? selectedRole;
  final AuthStatus status;
  final AuthUserModel? user;
  final String? errorMessage;

  const AuthState({
    this.selectedRole,
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    UserRole? selectedRole,
    AuthStatus? status,
    AuthUserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      selectedRole: selectedRole ?? this.selectedRole,
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [selectedRole, status, user, errorMessage];
}
