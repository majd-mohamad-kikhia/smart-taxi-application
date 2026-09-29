import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ride_history_model.dart';
import '../../data/repositories/trips_repository.dart';
import 'trips_state.dart';

/// Loads the customer's rides page by page (`GET /api/customer/rides`).
class TripsCubit extends Cubit<TripsState> {
  final TripsRepository _repository;

  TripsCubit(this._repository) : super(const TripsState());

  Future<void> initialize() => _load(1, replace: true);

  Future<void> refresh() => _load(1, replace: true);

  /// Filters by [status]; `null` shows every ride.
  Future<void> selectStatus(RideStatus? status) {
    if (state.selectedStatus == status) return Future.value();
    emit(state.copyWith(
      rides: const [],
      selectedStatus: status,
      clearStatus: status == null,
      page: 0,
      totalPages: 1,
    ));
    return _load(1, replace: true);
  }

  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return Future.value();
    }
    return _load(state.page + 1, replace: false);
  }

  Future<void> _load(int page, {required bool replace}) async {
    if (isClosed) return;
    emit(state.copyWith(
      isLoading: replace && state.rides.isEmpty,
      isLoadingMore: !replace,
      clearError: true,
    ));
    try {
      final requested = state.selectedStatus;
      final result = await _repository.getRides(
        page: page,
        statusId: requested?.id,
      );
      if (isClosed || requested != state.selectedStatus) return;
      emit(state.copyWith(
        rides: replace ? result.rides : [...state.rides, ...result.rides],
        page: result.page,
        totalPages: result.totalPages,
        isLoading: false,
        isLoadingMore: false,
      ));
    } on TripsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.message,
      ));
    }
  }
}
