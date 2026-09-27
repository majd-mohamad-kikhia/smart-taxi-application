import 'package:dio/dio.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_user_model.dart';

/// Structured failure thrown by [AuthRepository], so the Cubit never has
/// to interpret a raw exception.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Repository for the Auth feature.
///
/// The Cubit talks to this, never to [AuthRemoteDataSource] /
/// [AuthLocalDataSource] directly, so either can change without touching
/// presentation code.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  const AuthRepository(this._remoteDataSource, this._localDataSource);

  Future<AuthUserModel> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        phone: phone,
        password: password,
        role: role,
      );
      await _persistSession(user);
      return user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<AuthUserModel> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        role: role,
      );
      await _persistSession(user);
      return user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Loads a previously-saved session (if any) at app startup and primes
  /// [ApiClient] with its token, so the app can skip straight to
  /// [AppRouter.home] instead of the auth flow.
  Future<AuthUserModel?> restoreSession() async {
    final user = await _localDataSource.loadSession();
    if (user != null) {
      ApiClient.authToken = user.accessToken;
    }
    return user;
  }

  /// Revokes the current device's session on the server, then always
  /// clears the local session/token — even if the network call fails
  /// (e.g. no connection, or the token already expired), so the user is
  /// never stuck unable to log out.
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

  Future<void> _persistSession(AuthUserModel user) async {
    ApiClient.authToken = user.accessToken;
    await _localDataSource.saveSession(user);
  }

  AuthException _mapDioException(DioException e) {
    final error = e.error;
    return AuthException(
      error is ApiException ? error.message : 'تعذر الاتصال بالخادم',
    );
  }
}
