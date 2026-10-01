import 'package:dio/dio.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../models/notifications_page_model.dart';

/// Repository for the customer notifications. Failures surface as
/// [ApiException] so the Cubit never sees a raw `DioException`.
class NotificationsRepository {
  static const int pageSize = 20;

  final NotificationsRemoteDataSource _remote;

  const NotificationsRepository(this._remote);

  Future<NotificationsPageModel> getPage(int page) =>
      _guard(() => _remote.fetchNotifications(page: page, limit: pageSize));

  /// How many notifications are unread (the bell's badge), without loading a
  /// whole page of them.
  Future<int> getUnreadCount() async {
    final page = await _guard(
      () => _remote.fetchNotifications(page: 1, limit: 1),
    );
    return page.unreadCount;
  }

  Future<void> markRead(int id) => _guard(() => _remote.markRead(id));

  Future<void> markAllRead() => _guard(_remote.markAllRead);

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
