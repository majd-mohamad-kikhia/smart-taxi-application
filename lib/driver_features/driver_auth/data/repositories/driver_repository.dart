import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_check.dart';
import '../datasources/driver_local_data_source.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/driver_remote_data_source.dart';
import '../models/driver_user_model.dart';

class DriverAuthException implements Exception {
  final String message;

  const DriverAuthException(this.message);

  @override
  String toString() => message;
}

class DriverRepository {
  final DriverRemoteDataSource _remoteDataSource;
  final DriverLocalDataSource _localDataSource;

  const DriverRepository(this._remoteDataSource, this._localDataSource);

  Future<DriverUserModel> login({
    required String phone,
    required String password,
  }) async {
    try {
      final driver = await _remoteDataSource.login(
        phone: phone,
        password: password,
      );
      await _persistSession(driver);
      return driver;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Loads a previously-saved session (if any) at app startup and primes
  /// [ApiClient] with its token, so the app can skip straight to the
  /// driver home shell instead of the auth flow.
  Future<DriverUserModel?> restoreSession() async {
    final driver = await _localDataSource.loadSession();
    if (driver != null) {
      ApiClient.authToken = driver.accessToken;
    }
    return driver;
  }

  /// Whether the server no longer accepts the restored session's token
  /// (expired, or the account was deleted). `false` when offline.
  Future<bool> isSessionRejected() => isTokenRejected(_remoteDataSource.checkSession);

  /// Revokes the current device's session on the server, then always
  /// clears the local session/token — even if the network call fails —
  /// so the driver is never stuck unable to log out.
  Future<void> logout() async {
    try {
      final session = await _localDataSource.loadSession();
      if (session != null) {
        await _remoteDataSource.logout(refreshToken: session.refreshToken);
      }
    } on DioException {
      // Best-effort — local session is cleared below regardless.
    } finally {
      ApiClient.authToken = null;
      await _localDataSource.clearSession();
    }
  }

  /// Updates the driver's ride-search radius on the server, then keeps the
  /// locally-cached session in sync so a restart doesn't show a stale value.
  Future<double> updateSearchRadius(double searchRadiusKm) async {
    try {
      final updated = await _remoteDataSource.updateSearchRadius(searchRadiusKm);
      final session = await _localDataSource.loadSession();
      if (session != null) {
        await _localDataSource.saveSession(
          session.copyWith(searchRadiusKm: updated),
        );
      }
      return updated;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> _persistSession(DriverUserModel driver) async {
    ApiClient.authToken = driver.accessToken;
    await _localDataSource.saveSession(driver);
  }

  DriverAuthException _mapDioException(DioException e) {
    final error = e.error;
    return DriverAuthException(
      error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
    );
  }
}
