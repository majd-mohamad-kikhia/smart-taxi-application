import 'notification_model.dart';

/// One page of `GET /api/customer/notifications` (swagger
/// `NotificationListData`): the rows, the pagination info and how many
/// notifications are unread in total (the bell's badge).
class NotificationsPageModel {
  final List<NotificationModel> notifications;
  final int page;
  final int totalPages;
  final int unreadCount;

  const NotificationsPageModel({
    required this.notifications,
    required this.page,
    required this.totalPages,
    this.unreadCount = 0,
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
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
