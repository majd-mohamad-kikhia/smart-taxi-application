import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the driver chose to be online, so the app can connect
/// again by itself after it was closed or restarted — without waiting for the
/// toggle to be tapped. Cleared when the driver goes offline or logs out.
class DriverPresenceStore {
  static const _key = 'driver_wants_online';

  Future<bool> wantsOnline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('DriverPresenceStore: could not read: $e');
      return false;
    }
  }

  Future<void> setWantsOnline(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('DriverPresenceStore: could not save: $e');
    }
  }
}
