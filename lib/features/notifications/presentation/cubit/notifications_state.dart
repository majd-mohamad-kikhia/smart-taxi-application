import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

/// Immutable state for the Notifications screen.
class NotificationsState extends Equatable {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.errorMessage,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      notifications: [],
      isLoading: true,
    );
  }

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, errorMessage];
}
