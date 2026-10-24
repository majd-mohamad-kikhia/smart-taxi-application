import 'package:shared_preferences/shared_preferences.dart';

/// The app no longer keeps any searched place on the device. Older versions
/// kept a list of picked places (some of it Google's text); this deletes it,
/// once per start, for every customer who had it.
Future<void> deleteSavedPlacesFromDevice() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in const ['recent_places', 'place_history_v2']) {
    if (prefs.containsKey(key)) await prefs.remove(key);
  }
}
