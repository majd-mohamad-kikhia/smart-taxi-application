import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/driver_ratings_repository.dart';
import 'driver_ratings_state.dart';

/// Loads the driver's ratings a page at a time. The summary comes with every
/// page and is kept from the latest one.
class DriverRatingsCubit extends Cubit<DriverRatingsState> {
  final DriverRatingsRepository _repository;

  DriverRatingsCubit(this._repository) : super(const DriverRatingsState());

  /// First page; also the pull-to-refresh and the retry. A refresh on top of
  /// a list already shown keeps it on screen.
  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: !state.isLoaded, clearError: true));
    try {
      final page = await _repository.getRatings(page: 1);
      if (isClosed) return;
      emit(DriverRatingsState(
        isLoading: false,
        isLoaded: true,
        summary: page.summary,
        ratings: page.ratings,
        page: page.page,
        hasMore: page.hasMore,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> loadMore() async {
    if (isClosed || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await _repository.getRatings(page: state.page + 1);
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        summary: page.summary,
        ratings: [...state.ratings, ...page.ratings],
        page: page.page,
        hasMore: page.hasMore,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.message));
    }
  }
}
