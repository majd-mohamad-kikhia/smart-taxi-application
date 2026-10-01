import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notifications_page_model.dart';

/// Remote data source for `/api/customer/notifications` (see swagger.json).
class NotificationsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const NotificationsRemoteDataSource(this._dio, this._endpoints);

  /// Newest first. [limit] is 1–100 per swagger.
  Future<NotificationsPageModel> fetchNotifications({
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      _endpoints.customerNotifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    return NotificationsPageModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// `PUT /api/customer/notifications/{id}/read`.
  Future<void> markRead(int id) async {
    await _dio.put(_endpoints.customerNotificationRead(id));
  }

  /// `PUT /api/customer/notifications/read-all`.
  Future<void> markAllRead() async {
    await _dio.put(_endpoints.customerNotificationsReadAll);
  }
}
