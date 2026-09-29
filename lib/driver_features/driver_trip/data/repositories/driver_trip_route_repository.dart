import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/driver_trip_remote_data_source.dart';
import '../datasources/driver_trip_route_local_data_source.dart';
import '../models/recorded_route_point_model.dart';

/// Saves a trip's recorded route on the device and uploads it after the
/// ride is finished (`PUT /api/driver/rides/{id}/route`). A singleton, so
/// an upload that is still retrying survives the trip screen closing.
///
/// Nothing here throws: the route must never get in the way of finishing
/// a trip or confirming payment. Failures are logged; unsent routes stay
/// on the device and are retried by [uploadPending] on the next launch.
class DriverTripRouteRepository {
  static const _maxPoints = 5000;
  static const _uploadWindow = Duration(hours: 72);
  static const _retryDelays = [Duration(seconds: 3), Duration(seconds: 10)];

  final DriverTripRemoteDataSource _remote;
  final DriverTripRouteLocalDataSource _local;
  final Set<int> _uploading = {};

  DriverTripRouteRepository(this._remote, this._local);

  /// Periodic safety copy while the trip is running.
  Future<void> saveDraft(int rideId, List<RecordedRoutePointModel> points) async {
    try {
      await _local.save(rideId, points, isFinished: false);
    } catch (e) {
      debugPrint('DriverTripRouteRepository: failed to save draft: $e');
    }
  }

  /// The ride was finished on the server: persist the final list, then
  /// upload it (with retries).
  Future<void> finishAndUpload(int rideId, List<RecordedRoutePointModel> points) async {
    try {
      await _local.save(rideId, points, isFinished: true);
    } catch (e) {
      debugPrint('DriverTripRouteRepository: failed to save route: $e');
    }
    await _upload(rideId, points);
  }

  /// Uploads routes left over from earlier trips (app killed, offline, …)
  /// and drops the ones the server would no longer accept.
  Future<void> uploadPending() async {
    final List<PendingRouteModel> pending;
    try {
      pending = await _local.loadAll();
    } catch (e) {
      debugPrint('DriverTripRouteRepository: failed to read saved routes: $e');
      return;
    }
    for (final entry in pending) {
      if (DateTime.now().difference(entry.savedAt) > _uploadWindow) {
        await _forget(entry.rideId);
      } else if (entry.isFinished) {
        await _upload(entry.rideId, entry.points);
      }
    }
  }

  Future<void> _upload(int rideId, List<RecordedRoutePointModel> points) async {
    if (!_uploading.add(rideId)) return;
    try {
      // The server needs at least 2 points, so there is nothing to send.
      if (points.length < 2) {
        await _forget(rideId);
        return;
      }
      final body = _capPoints(points);
      for (var attempt = 0; ; attempt++) {
        try {
          await _remote.uploadRoute(rideId: rideId, points: body);
          await _forget(rideId);
          return;
        } on DioException catch (e) {
          final error = e.error;
          final statusCode = error is ApiException ? error.statusCode : null;
          final retryable = statusCode == null || statusCode >= 500;
          if (!retryable) {
            // The server refused this route for good (wrong ride, window
            // closed, invalid points): keeping it would only retry forever.
            debugPrint('DriverTripRouteRepository: route $rideId rejected ($statusCode): $error');
            await _forget(rideId);
            return;
          }
          if (attempt >= _retryDelays.length) {
            debugPrint('DriverTripRouteRepository: route $rideId upload failed, will retry next launch');
            return;
          }
          await Future<void>.delayed(_retryDelays[attempt]);
        }
      }
    } finally {
      _uploading.remove(rideId);
    }
  }

  /// The server accepts at most 5000 points; keeps them evenly spread,
  /// always including the first and last.
  List<RecordedRoutePointModel> _capPoints(List<RecordedRoutePointModel> points) {
    if (points.length <= _maxPoints) return points;
    final step = (points.length - 1) / (_maxPoints - 1);
    return [for (var i = 0; i < _maxPoints; i++) points[(i * step).round()]];
  }

  Future<void> _forget(int rideId) async {
    try {
      await _local.remove(rideId);
    } catch (e) {
      debugPrint('DriverTripRouteRepository: failed to clear saved route: $e');
    }
  }
}
