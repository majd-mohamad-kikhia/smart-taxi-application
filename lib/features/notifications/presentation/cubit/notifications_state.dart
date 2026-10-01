import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

class NotificationsState extends Equatable {
  final List<NotificationModel> notifications;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const NotificationsState({
    required this.notifications,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.errorMessage,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      notifications: [],
      page: 0,
      hasMore: false,
      isLoading: true,
      isLoadingMore: false,
    );
  }

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    page,
    hasMore,
    isLoading,
    isLoadingMore,
    errorMessage,
  ];
}
