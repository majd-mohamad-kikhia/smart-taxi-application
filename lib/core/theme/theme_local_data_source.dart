import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the chosen theme locally via [SharedPreferences], so it survives
/// app restarts. Unknown or missing values mean "no choice yet".
class ThemeLocalDataSource {
  static const _themeKey = 'app_theme_mode';

  const ThemeLocalDataSource();

  Future<ThemeMode?> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };
  }

  Future<void> saveMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
