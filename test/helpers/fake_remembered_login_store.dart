import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/session/remembered_login.dart';
import 'package:mshoar/core/session/remembered_login_store.dart';

/// "Remember me" kept in memory, so cubit tests never touch secure storage.
class FakeRememberedLoginStore extends RememberedLoginStore {
  final Map<UserRole, RememberedLogin> saved = {};

  @override
  Future<RememberedLogin?> load(UserRole role) async => saved[role];

  @override
  Future<void> save(
    UserRole role, {
    required String phone,
    required String password,
  }) async {
    saved[role] = RememberedLogin(phone: phone, password: password);
  }

  @override
  Future<void> clear(UserRole role) async {
    saved.remove(role);
  }
}
