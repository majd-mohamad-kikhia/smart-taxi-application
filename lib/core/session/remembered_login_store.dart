import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../enums/user_role.dart';
import 'remembered_login.dart';

/// Keeps the sign-in the customer or the driver chose to be remembered
/// ("Remember me"), one per [UserRole], in the phone's secure storage: the
/// iOS Keychain, or Android's encrypted key store. The password is never
/// written to ordinary preferences, never leaves the phone, and on iOS it is
/// not carried to another device by a backup.
///
/// A storage that fails (a damaged key store, a restored backup that can't be
/// decrypted) must never stop anyone from signing in: it is logged, and the
/// sign-in form is simply left empty.
class RememberedLoginStore {
  final FlutterSecureStorage _storage;

  const RememberedLoginStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static String _phoneKey(UserRole role) => 'remember_me_${role.name}_phone';
  static String _passwordKey(UserRole role) =>
      'remember_me_${role.name}_password';

  /// What [role] asked to be remembered, or null when nothing was.
  Future<RememberedLogin?> load(UserRole role) async {
    try {
      final phone = await _storage.read(key: _phoneKey(role));
      final password = await _storage.read(key: _passwordKey(role));
      if (phone == null || phone.isEmpty || password == null) return null;
      return RememberedLogin(phone: phone, password: password);
    } on Exception catch (e) {
      debugPrint('RememberedLoginStore: could not read the saved login: $e');
      return null;
    }
  }

  Future<void> save(
    UserRole role, {
    required String phone,
    required String password,
  }) async {
    try {
      await _storage.write(key: _phoneKey(role), value: phone);
      await _storage.write(key: _passwordKey(role), value: password);
    } on Exception catch (e) {
      debugPrint('RememberedLoginStore: could not save the login: $e');
    }
  }

  Future<void> clear(UserRole role) async {
    try {
      await _storage.delete(key: _phoneKey(role));
      await _storage.delete(key: _passwordKey(role));
    } on Exception catch (e) {
      debugPrint('RememberedLoginStore: could not clear the saved login: $e');
    }
  }
}
