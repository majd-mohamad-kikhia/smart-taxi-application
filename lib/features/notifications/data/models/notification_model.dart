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
  final bool isRead;

  /// The trip this notification is about, when it is about one.
  final int? relatedRideId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sentAt,
    this.isRead = false,
    this.relatedRideId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['body'] as String? ?? '',
      type: NotificationType.fromKey(json['notification_type'] as String),
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      relatedRideId: (json['related_ride_id'] as num?)?.toInt(),
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        sentAt: sentAt,
        isRead: isRead ?? this.isRead,
        relatedRideId: relatedRideId,
      );

  @override
  List<Object?> get props =>
      [id, title, message, type, sentAt, isRead, relatedRideId];
}
