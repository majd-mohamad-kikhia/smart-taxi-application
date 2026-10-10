import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/session/app_user.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/driver_user_model.dart';
import '../../data/repositories/driver_repository.dart';
import 'driver_auth_state.dart';

/// Cubit driving driver sign in (and session restore/logout).
///
/// Registered as a singleton (see injection.dart), matching the customer
/// `AuthCubit`, so [DriverAuthState.driver] survives navigation from sign
/// in into the driver app shell.
class DriverAuthCubit extends Cubit<DriverAuthState> {
  final DriverRepository _repository;
  final SessionCubit _sessionCubit;

  DriverAuthCubit(this._repository, this._sessionCubit)
      : super(DriverAuthState.initial());

  /// Primes the state from a session [DriverRepository.restoreSession]
  /// already found locally, so the driver shell sees a signed-in driver
  /// without going through the sign in form again.
  void hydrate(DriverUserModel driver) {
    _sessionCubit.setUser(_toAppUser(driver));
    emit(state.copyWith(status: DriverAuthStatus.success, driver: driver));
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: DriverAuthStatus.submitting, clearError: true));
    try {
      final driver = await _repository.login(phone: phone, password: password);
      if (isClosed) return;
      _sessionCubit.setUser(_toAppUser(driver));
      emit(state.copyWith(
        status: DriverAuthStatus.success,
        driver: driver,
        walletBalance: driver.walletBalance,
      ));
    } on DriverAuthException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: DriverAuthStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  /// Asks the server for the wallet balance as it is now, so the home
  /// screen can warn about a low one. Quiet when it fails: the notice is an
  /// early hint, and accepting an order is refused by the server anyway.
  Future<void> refreshWalletBalance() async {
    if (state.driver == null) return;
    try {
      final balance = await _repository.walletBalance();
      if (!isClosed) emit(state.copyWith(walletBalance: balance));
    } on DriverAuthException catch (e) {
      debugPrint('DriverAuthCubit: could not refresh the wallet balance: $e');
    }
  }

  /// Updates the signed-in driver's search radius and reflects it in
  /// [state.driver] once the server confirms it. Throws
  /// [DriverAuthException] on failure — callers decide how to surface it.
  Future<void> updateSearchRadius(double searchRadiusKm) async {
    final updated = await _repository.updateSearchRadius(searchRadiusKm);
    if (isClosed) return;
    final driver = state.driver;
    if (driver != null) {
      emit(state.copyWith(driver: driver.copyWith(searchRadiusKm: updated)));
    }
  }

  /// A customer just rated the driver: the profile shows the server's new
  /// average from now on.
  void applyRating(double average) {
    final driver = state.driver;
    if (isClosed || driver == null || driver.rating == average) return;
    emit(state.copyWith(driver: driver.copyWith(rating: average)));
  }

  /// Clears a submit error/result so the form can be retried.
  void resetStatus() {
    emit(state.copyWith(status: DriverAuthStatus.idle, clearError: true));
  }

  Future<void> logout() async {
    await _repository.logout();
    _sessionCubit.clear();
    if (!isClosed) emit(DriverAuthState.initial());
  }

  AppUser _toAppUser(DriverUserModel driver) => AppUser(
        id: driver.id,
        fullName: driver.fullName,
        phone: driver.phone,
        photoUrl: driver.photoUrl,
        role: UserRole.driver,
      );
}
