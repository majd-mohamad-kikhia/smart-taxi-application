import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/notifications/unread_notifications_cubit.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  final UnreadNotificationsCubit _unread;

  NotificationsCubit(this._repository, this._unread)
      : super(NotificationsState.initial());

  /// Loads the first page, replacing whatever is shown.
  Future<void> initialize() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final page = await _repository.getPage(1);
      if (isClosed) return;
      emit(
        state.copyWith(
          notifications: page.notifications,
          page: page.page,
          hasMore: page.hasMore,
          unreadCount: page.unreadCount,
          isLoading: false,
        ),
      );
      _unread.set(page.unreadCount);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: _messageOf(e)));
    }
  }

  /// Appends the next page. A failure keeps the list and stays retryable.
  Future<void> loadMore() async {
    if (isClosed || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = await _repository.getPage(state.page + 1);
      if (isClosed) return;
      emit(
        state.copyWith(
          notifications: [...state.notifications, ...next.notifications],
          page: next.page,
          hasMore: next.hasMore,
          unreadCount: next.unreadCount,
          isLoadingMore: false,
        ),
      );
      _unread.set(next.unreadCount);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, errorMessage: _messageOf(e)));
    }
  }

  /// Marks one notification read. It changes on screen at once and is put
  /// back, with the error, if the server refuses.
  Future<void> markRead(int id) async {
    if (isClosed) return;
    final before = state;
    final target = state.notifications.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    _applyReadState(
      notifications: [
        for (final n in state.notifications)
          n.id == id ? n.copyWith(isRead: true) : n,
      ],
      unreadCount: state.unreadCount - 1,
    );
    try {
      await _repository.markRead(id);
    } catch (e) {
      if (isClosed) return;
      _applyReadState(
        notifications: before.notifications,
        unreadCount: before.unreadCount,
      );
      emit(state.copyWith(errorMessage: _messageOf(e)));
    }
  }

  /// Marks every notification read, with the same put-back on failure.
  Future<void> markAllRead() async {
    if (isClosed || state.unreadCount == 0) return;
    final before = state;
    _applyReadState(
      notifications: [
        for (final n in state.notifications) n.copyWith(isRead: true),
      ],
      unreadCount: 0,
    );
    try {
      await _repository.markAllRead();
    } catch (e) {
      if (isClosed) return;
      _applyReadState(
        notifications: before.notifications,
        unreadCount: before.unreadCount,
      );
      emit(state.copyWith(errorMessage: _messageOf(e)));
    }
  }

  void _applyReadState({
    required List<NotificationModel> notifications,
    required int unreadCount,
  }) {
    final count = unreadCount < 0 ? 0 : unreadCount;
    emit(state.copyWith(notifications: notifications, unreadCount: count));
    _unread.set(count);
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : AppStrings.current.errUnexpected;
}
