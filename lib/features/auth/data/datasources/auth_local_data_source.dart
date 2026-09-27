import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/enums/user_role.dart';
import '../models/auth_user_model.dart';

/// Persists the signed-in session locally via [SharedPreferences], so the
/// app doesn't force a fresh login on every restart.
///
/// Deliberately stores only what a successful login/signup already
/// returned (profile + tokens) — never the password.
class AuthLocalDataSource {
  static const _sessionKey = 'auth_session';

  const AuthLocalDataSource();

  Future<void> saveSession(AuthUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'id': user.id,
        'full_name': user.fullName,
        'phone': user.phone,
        'email': user.email,
        'photo_url': user.photoUrl,
        'address': user.address,
        'role': user.role.name,
        'access_token': user.accessToken,
        'refresh_token': user.refreshToken,
      }),
    );
  }

  Future<AuthUserModel?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AuthUserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      address: json['address'] as String?,
      role: UserRole.values.byName(json['role'] as String),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
