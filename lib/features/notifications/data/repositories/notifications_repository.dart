import '../datasources/notifications_remote_data_source.dart';
import '../models/notification_model.dart';

/// Structured failure thrown by [NotificationsRepository] on a non-200
/// response, so the Cubit never has to interpret raw exceptions.
class NotificationsException implements Exception {
  final String message;

  const NotificationsException(this.message);

  @override
  String toString() => message;
}

/// Repository for the Notifications feature.
///
/// The Cubit talks to this, never to [NotificationsRemoteDataSource]
/// directly, so the mocked data source can be replaced with a real API
/// client without touching presentation code.
class NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  const NotificationsRepository(this._remoteDataSource);

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _remoteDataSource.fetchNotifications();
    if (response.statusCode != 200) {
      throw const NotificationsException('تعذر تحميل الإشعارات');
    }
    return response.data;
  }
}
