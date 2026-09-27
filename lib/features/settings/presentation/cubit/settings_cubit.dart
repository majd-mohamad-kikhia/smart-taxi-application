import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';

/// Cubit managing the Profile / Settings screen state.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState.initial());

  void initialize() {
    if (!isClosed) emit(SettingsState.initial());
  }

  void toggleNotifications(bool enabled) {
    if (isClosed || state.notificationsEnabled == enabled) return;
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> logout() async {
    if (isClosed || state.isLoggingOut) return;
    emit(state.copyWith(isLoggingOut: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!isClosed) {
      emit(state.copyWith(isLoggingOut: false));
    }
  }

  void onItemTapped(String itemId) {
    // Placeholder – route to sub-screens in later iterations
  }
}
