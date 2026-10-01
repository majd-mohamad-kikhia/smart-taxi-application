import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version_model.dart';

/// Remembers which `latest_version` the user dismissed with "Later", per app,
/// so the optional-update dialog only comes back for a newer release.
class AppVersionLocalDataSource {
  const AppVersionLocalDataSource();

  static String _key(AppVersionApp app) => 'app_version_skipped_${app.name}';

  Future<String?> loadSkippedVersion(AppVersionApp app) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(app));
  }

  Future<void> saveSkippedVersion(AppVersionApp app, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(app), version);
  }
}
