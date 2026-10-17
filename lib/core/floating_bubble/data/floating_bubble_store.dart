import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the driver's "Floating bubble" switch (off until turned on).
class FloatingBubbleStore {
  static const _key = 'floating_bubble_enabled';

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('FloatingBubbleStore: could not read: $e');
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('FloatingBubbleStore: could not save: $e');
    }
  }
}
