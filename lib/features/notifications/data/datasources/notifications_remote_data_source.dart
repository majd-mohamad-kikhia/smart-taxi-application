import '../../../../core/localization/app_strings.dart';
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

  /// Sample data, worded in the language active at fetch time.
  static List<NotificationModel> get _mockNotifications {
    final l10n = AppStrings.current;
    return [
      NotificationModel(
        id: 'n1',
        title: l10n.mockNotif1Title,
        message: l10n.mockNotif1Message,
        type: NotificationType.tripUpdate,
        dateTime: DateTime(2025, 10, 24, 14, 10),
      ),
      NotificationModel(
        id: 'n2',
        title: l10n.mockNotif2Title,
        message: l10n.mockNotif2Message,
        type: NotificationType.promo,
        dateTime: DateTime(2025, 10, 24, 10, 0),
      ),
      NotificationModel(
        id: 'n3',
        title: l10n.mockNotif3Title,
        message: l10n.mockNotif3Message,
        type: NotificationType.payment,
        dateTime: DateTime(2025, 10, 24, 8, 45),
      ),
      NotificationModel(
        id: 'n4',
        title: l10n.mockNotif4Title,
        message: l10n.mockNotif4Message,
        type: NotificationType.tripUpdate,
        dateTime: DateTime(2025, 10, 23, 20, 30),
      ),
      NotificationModel(
        id: 'n5',
        title: l10n.mockNotif5Title,
        message: l10n.mockNotif5Message,
        type: NotificationType.promo,
        dateTime: DateTime(2025, 10, 19, 12, 0),
      ),
      NotificationModel(
        id: 'n6',
        title: l10n.mockNotif6Title,
        message: l10n.mockNotif6Message,
        type: NotificationType.system,
        dateTime: DateTime(2025, 10, 19, 9, 0),
      ),
    ];
  }
}
