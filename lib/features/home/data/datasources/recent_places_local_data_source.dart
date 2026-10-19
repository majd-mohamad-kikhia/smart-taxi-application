import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_suggestion_model.dart';

/// Keeps the places the customer picked from a search on the device, newest
/// first, as one small JSON list under a single [SharedPreferences] key
/// (description + coordinates only). The plugin holds its values in memory
/// once loaded, so reading on every keystroke costs nothing.
class RecentPlacesLocalDataSource {
  static const _key = 'recent_places';

  const RecentPlacesLocalDataSource();

  /// The saved places, newest first. A corrupt value is dropped rather than
  /// allowed to break the search.
  Future<List<PlaceSuggestionModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final entry in list)
          PlaceSuggestionModel.fromJson(entry as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('RecentPlacesLocalDataSource: dropped a corrupt cache: $e');
      await prefs.remove(_key);
      return const [];
    }
  }

  Future<void> save(List<PlaceSuggestionModel> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final place in places) place.toJson()]),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
