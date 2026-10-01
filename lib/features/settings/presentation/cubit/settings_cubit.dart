import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SessionCubit _sessionCubit;

  SettingsCubit(this._sessionCubit) : super(SettingsState.initial());

  /// Fills the profile from the signed-in customer. With nobody signed in the
  /// card stays blank.
  void initialize() {
    if (isClosed) return;
    final user = _sessionCubit.state;
    final initial = SettingsState.initial();
    if (user == null) {
      emit(initial);
      return;
    }
    emit(
      initial.copyWith(
        profile: initial.profile.copyWith(
          id: user.id.toString(),
          fullName: user.fullName,
          phone: user.phone,
          photoUrl: user.photoUrl,
          email: user.email ?? '',
        ),
      ),
    );
  }

  Future<void> logout() async {
    if (isClosed || state.isLoggingOut) return;
    emit(state.copyWith(isLoggingOut: true));
    await _sessionCubit.logout();
    if (!isClosed) {
      emit(state.copyWith(isLoggingOut: false));
    }
  }
}
