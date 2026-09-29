import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen language code locally via
/// [SharedPreferences], so it survives app restarts.
class LocaleLocalDataSource {
  static const _languageCodeKey = 'app_language_code';

  const LocaleLocalDataSource();

  Future<String?> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey);
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }
}
