import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/session/app_user.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/auth_user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit driving the auth flow: role selection, sign in and sign up.
///
/// Registered as a singleton (see injection.dart) rather than a
/// per-screen factory, because [selectedRole] must survive navigation
/// from the role-selection screen into sign in / sign up.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final SessionCubit _sessionCubit;

  AuthCubit(this._repository, this._sessionCubit) : super(AuthState.initial());

  void selectRole(UserRole role) {
    emit(state.copyWith(selectedRole: role));
  }

  /// Primes the state from a session [AuthRepository.restoreSession]
  /// already found locally, so the rest of the app sees a signed-in user
  /// without going through the sign in form again.
  void hydrate(AuthUserModel user) {
    _sessionCubit.setUser(_toAppUser(user));
    emit(state.copyWith(
      status: AuthStatus.success,
      user: user,
      selectedRole: user.role,
    ));
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    final role = state.selectedRole;
    if (role == null || isClosed) return;

    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    try {
      final user = await _repository.login(
        phone: phone,
        password: password,
        role: role,
      );
      if (isClosed) return;
      _sessionCubit.setUser(_toAppUser(user));
      emit(state.copyWith(status: AuthStatus.success, user: user));
    } on AuthException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.message));
    }
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    final role = state.selectedRole;
    if (role == null || isClosed) return;

    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    try {
      final user = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        role: role,
      );
      if (isClosed) return;
      _sessionCubit.setUser(_toAppUser(user));
      emit(state.copyWith(status: AuthStatus.success, user: user));
    } on AuthException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.message));
    }
  }

  /// Clears a submit error/result so the form can be retried, without
  /// losing [AuthState.selectedRole].
  void resetStatus() {
    emit(state.copyWith(status: AuthStatus.idle, clearError: true));
  }

  Future<void> logout() async {
    await _repository.logout();
    _sessionCubit.clear();
    if (!isClosed) emit(AuthState.initial());
  }

  AppUser _toAppUser(AuthUserModel user) => AppUser(
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        email: user.email,
        photoUrl: user.photoUrl,
        role: user.role,
      );
}
