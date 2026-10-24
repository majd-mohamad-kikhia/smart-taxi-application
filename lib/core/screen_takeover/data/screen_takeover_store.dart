import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the driver's "Open the app for new orders" switch (on until
/// turned off) and the app version whose permissions were last checked.
class ScreenTakeoverStore {
  static const _enabledKey = 'screen_takeover_enabled';
  static const _checkedVersionKey = 'screen_takeover_checked_version';

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? true;
    } catch (e) {
      debugPrint('ScreenTakeoverStore: could not read: $e');
      return true;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      debugPrint('ScreenTakeoverStore: could not save: $e');
    }
  }

  /// The version (`1.2.3+4`) the permissions were last checked for, or null
  /// when they never were.
  Future<String?> checkedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_checkedVersionKey);
    } catch (e) {
      debugPrint('ScreenTakeoverStore: could not read the version: $e');
      return null;
    }
  }

  Future<void> setCheckedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_checkedVersionKey, version);
    } catch (e) {
      debugPrint('ScreenTakeoverStore: could not save the version: $e');
    }
  }
}
