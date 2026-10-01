import 'package:equatable/equatable.dart';

/// Category of a notification, driving its icon and color.
enum NotificationType {
  ride,
  system;

  /// swagger.json documents `notification_type` as an app-defined key
  /// (`ride_accepted`, `manager_message`, `manager_broadcast`, ...):
  /// `ride_*` keys are trip updates, anything else is a system message.
  static NotificationType fromKey(String key) =>
      key.startsWith('ride_') ? ride : system;
}

/// A single entry of `GET /api/customer/notifications` (swagger
/// `Notification` schema).
class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['body'] as String? ?? '',
      type: NotificationType.fromKey(json['notification_type'] as String),
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, sentAt];
}
