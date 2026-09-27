import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import 'settings_state.dart';

/// Cubit managing the Profile / Settings screen state.
class SettingsCubit extends Cubit<SettingsState> {
  final SessionCubit _sessionCubit;

  SettingsCubit(this._sessionCubit) : super(SettingsState.initial());

  /// Wallet balance / verification badge stay mock data (no wallet API
  /// yet) — only the identity fields come from the real signed-in user.
  void initialize() {
    if (isClosed) return;
    final user = _sessionCubit.state;
    final initial = SettingsState.initial();
    if (user == null) {
      emit(initial);
      return;
    }
    emit(initial.copyWith(
      profile: initial.profile.copyWith(
        id: user.id.toString(),
        fullName: user.fullName,
        phone: user.phone,
        email: user.email,
      ),
    ));
  }

  Future<void> logout() async {
    if (isClosed || state.isLoggingOut) return;
    emit(state.copyWith(isLoggingOut: true));
    await _sessionCubit.logout();
    if (!isClosed) {
      emit(state.copyWith(isLoggingOut: false));
    }
  }

  void onItemTapped(String itemId) {
    // Placeholder – route to sub-screens in later iterations
  }
}
