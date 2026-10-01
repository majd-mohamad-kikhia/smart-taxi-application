import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_session_model.dart';

/// Keeps the driver's private route on the device — one [SharedPreferences]
/// entry, replaced on every save and removed when a new route is started.
class RouteSessionLocalDataSource {
  static const _key = 'driver_route_session';

  const RouteSessionLocalDataSource();

  Future<RouteSessionModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return RouteSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(RouteSessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
