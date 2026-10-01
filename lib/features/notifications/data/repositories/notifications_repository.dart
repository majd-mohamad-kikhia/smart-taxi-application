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

  Future<NotificationsPageModel> getPage(int page) async {
    try {
      return await _remote.fetchNotifications(page: page, limit: pageSize);
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
