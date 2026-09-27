import '../models/notification_model.dart';

/// Minimal stand-in for a future Dio [Response] until the real
/// notifications API is available.
class NotificationsApiResponse {
  final int statusCode;
  final List<NotificationModel> data;

  const NotificationsApiResponse({
    required this.statusCode,
    required this.data,
  });
}

/// Remote data source for the Notifications feature.
///
/// Mocked for now — always resolves with a 200 response and static data.
/// Once the backend is ready, swap the body of [fetchNotifications] for a
/// real Dio call; [NotificationsRepository] and everything above it stays
/// unchanged.
class NotificationsRemoteDataSource {
  Future<NotificationsApiResponse> fetchNotifications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return NotificationsApiResponse(statusCode: 200, data: _mockNotifications);
  }

  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'n1',
      title: 'الكابتن ماجد في الطريق إليك',
      message: 'سيصل كابتنك خلال 3 دقائق تقريباً، جهّز نفسك للانطلاق.',
      type: NotificationType.tripUpdate,
      dateTime: DateTime(2025, 10, 24, 14, 10),
    ),
    NotificationModel(
      id: 'n2',
      title: 'خصم 20% على مشاويرك',
      message: 'استخدم الرمز الترويجي "مشوار20" عند الحجز هذا الأسبوع.',
      type: NotificationType.promo,
      dateTime: DateTime(2025, 10, 24, 10, 0),
    ),
    NotificationModel(
      id: 'n3',
      title: 'تم خصم المبلغ بنجاح',
      message: 'تم خصم 38.50 ل.س من محفظتك مقابل رحلتك الأخيرة.',
      type: NotificationType.payment,
      dateTime: DateTime(2025, 10, 24, 8, 45),
    ),
    NotificationModel(
      id: 'n4',
      title: 'وصلت إلى وجهتك بنجاح',
      message: 'نتمنى أن تكون قد استمتعت برحلتك معنا. لا تنسَ تقييم الكابتن.',
      type: NotificationType.tripUpdate,
      dateTime: DateTime(2025, 10, 23, 20, 30),
    ),
    NotificationModel(
      id: 'n5',
      title: 'عرض خاص لعملاء مشوار',
      message: 'احصل على رحلة مجانية عند دعوة 3 أصدقاء للتطبيق.',
      type: NotificationType.promo,
      dateTime: DateTime(2025, 10, 19, 12, 0),
    ),
    NotificationModel(
      id: 'n6',
      title: 'تحديث سياسة الخصوصية',
      message: 'قمنا بتحديث سياسة الخصوصية وشروط الاستخدام الخاصة بالتطبيق.',
      type: NotificationType.system,
      dateTime: DateTime(2025, 10, 19, 9, 0),
    ),
  ];
}
