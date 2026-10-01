import 'package:flutter/foundation.dart';
import '../datasources/route_session_local_data_source.dart';
import '../models/route_session_model.dart';

/// Saves and restores the driver's private route. Nothing here throws: a
/// failed write is logged and the route simply stays in memory, so storage
/// trouble can never get in the way of the trip itself.
class RouteSessionRepository {
  final RouteSessionLocalDataSource _local;

  const RouteSessionRepository(this._local);

  /// The saved route, or null when there is none (or it is unreadable).
  Future<RouteSessionModel?> load() async {
    try {
      return await _local.load();
    } catch (e) {
      debugPrint('RouteSessionRepository: failed to read the saved route: $e');
      return null;
    }
  }

  Future<void> save(RouteSessionModel session) async {
    try {
      await _local.save(session);
    } catch (e) {
      debugPrint('RouteSessionRepository: failed to save the route: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _local.clear();
    } catch (e) {
      debugPrint('RouteSessionRepository: failed to clear the saved route: $e');
    }
  }
}
