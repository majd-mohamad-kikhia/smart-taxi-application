import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recorded_route_point_model.dart';

/// Keeps each trip's recorded route on the device until the server has
/// confirmed the upload, so a killed app or a dead network doesn't lose it
/// (the backend accepts late uploads for 72 hours).
///
/// One [SharedPreferences] entry per ride plus an index of ride ids.
class DriverTripRouteLocalDataSource {
  static const _idsKey = 'driver_trip_route_ids';
  static const _routeKeyPrefix = 'driver_trip_route_';

  const DriverTripRouteLocalDataSource();

  Future<void> save(
    int rideId,
    List<RecordedRoutePointModel> points, {
    required bool isFinished,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = PendingRouteModel(
      rideId: rideId,
      points: points,
      isFinished: isFinished,
      savedAt: DateTime.now(),
    );
    await prefs.setString('$_routeKeyPrefix$rideId', jsonEncode(entry.toJson()));
    final ids = (prefs.getStringList(_idsKey) ?? const <String>[]).toSet()
      ..add('$rideId');
    await prefs.setStringList(_idsKey, ids.toList());
  }

  Future<List<PendingRouteModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = <PendingRouteModel>[];
    for (final id in prefs.getStringList(_idsKey) ?? const <String>[]) {
      final raw = prefs.getString('$_routeKeyPrefix$id');
      if (raw == null) continue;
      entries.add(PendingRouteModel.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    return entries;
  }

  Future<void> remove(int rideId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_routeKeyPrefix$rideId');
    final ids = (prefs.getStringList(_idsKey) ?? const <String>[]).toSet()
      ..remove('$rideId');
    await prefs.setStringList(_idsKey, ids.toList());
  }
}
