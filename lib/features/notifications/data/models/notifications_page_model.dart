import 'notification_model.dart';

/// One page of `GET /api/customer/notifications` (swagger
/// `NotificationListData`): the rows and the pagination info.
class NotificationsPageModel {
  final List<NotificationModel> notifications;
  final int page;
  final int totalPages;

  const NotificationsPageModel({
    required this.notifications,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory NotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return NotificationsPageModel(
      notifications: (json['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      totalPages: pagination['total_pages'] as int,
    );
  }
}
