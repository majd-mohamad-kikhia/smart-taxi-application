import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on the device whether the first-launch onboarding was already
/// shown (finished or skipped), so it only ever appears once.
class OnboardingLocalDataSource {
  static const _seenKey = 'onboarding_seen';

  const OnboardingLocalDataSource();

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
