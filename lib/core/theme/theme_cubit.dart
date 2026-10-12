import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_local_data_source.dart';

/// The app's theme: [ThemeMode.light] or [ThemeMode.dark], dark until the
/// user chooses. The choice is saved on the device.
///
/// The whole app follows this cubit's state through `MaterialApp.themeMode`;
/// both themes are built once (see `AppTheme`), so switching only swaps them.
class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeLocalDataSource _local;

  ThemeCubit(this._local) : super(ThemeMode.dark);

  /// Restores the saved theme. Call once before `runApp` so the first frame is
  /// already in the right theme.
  Future<void> load() async {
    final saved = await _local.loadMode();
    if (saved != null && saved != state) emit(saved);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state || mode == ThemeMode.system) return;
    emit(mode);
    await _local.saveMode(mode);
  }
}
