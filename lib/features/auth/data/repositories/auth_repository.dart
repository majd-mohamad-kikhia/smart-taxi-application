import 'package:dio/dio.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_check.dart';
import '../datasources/auth_local_data_source.dart';
import '../../../../core/localization/app_strings.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_user_model.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

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

  /// Whether the server no longer accepts the restored session's token
  /// (expired, or the account was deleted). `false` when offline.
  Future<bool> isSessionRejected() => isTokenRejected(_remoteDataSource.checkSession);

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

  /// Keeps the locally-saved session's profile fields in sync after an
  /// edit made elsewhere in the app, so a restart doesn't show stale data.
  Future<void> syncStoredProfile({
    required String fullName,
    required String phone,
    required String? email,
    required String? photoUrl,
    String? address,
  }) async {
    final session = await _localDataSource.loadSession();
    if (session == null) return;
    await _localDataSource.saveSession(AuthUserModel(
      id: session.id,
      fullName: fullName,
      phone: phone,
      email: email,
      photoUrl: photoUrl,
      address: address ?? session.address,
      role: session.role,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    ));
  }

  Future<void> _persistSession(AuthUserModel user) async {
    ApiClient.authToken = user.accessToken;
    await _localDataSource.saveSession(user);
  }

  AuthException _mapDioException(DioException e) {
    final error = e.error;
    return AuthException(
      error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
    );
  }
}
