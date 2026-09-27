import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role.dart';
import 'app_user.dart';

/// App-wide "who is currently signed in" state, plus the logout trigger.
///
/// Lives in core (not a feature) because several features need to read
/// it (Settings' profile card, Home's greeting, the driver app's own
/// screens, ...) and/or trigger a logout, and features must not import
/// each other. Each account-holding feature (auth for riders, driver for
/// drivers) is the only writer for its own role — it calls
/// [setUser]/[clear] right after login/restore/logout, and plugs its
/// real logout implementation in via [registerLogoutHandler] keyed by
/// [UserRole]. Every other feature only reads this state
/// (BlocBuilder/`context.watch`) or calls [logout] — never mutates it
/// directly.
class SessionCubit extends Cubit<AppUser?> {
  final Map<UserRole, Future<void> Function()> _logoutHandlers = {};

  SessionCubit() : super(null);

  void registerLogoutHandler(UserRole role, Future<void> Function() handler) {
    _logoutHandlers[role] = handler;
  }

  void setUser(AppUser user) => emit(user);

  void clear() => emit(null);

  /// Dispatches to whichever feature owns the currently signed-in
  /// account's role.
  Future<void> logout() async {
    final role = state?.role;
    final handler = role != null ? _logoutHandlers[role] : null;
    if (handler != null) await handler();
  }
}
