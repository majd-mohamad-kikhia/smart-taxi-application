import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository) : super(NotificationsState.initial());

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
          isLoading: false,
        ),
      );
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
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, errorMessage: _messageOf(e)));
    }
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : AppStrings.current.errUnexpected;
}
