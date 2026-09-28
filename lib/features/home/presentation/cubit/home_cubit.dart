import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/picked_location_model.dart';
import '../../data/repositories/ride_request_repository.dart';
import 'home_state.dart';

/// Cubit managing the "إنشاء طلب" (create request) screen state.
/// Follows the principle of keeping business logic out of the UI layer.
class HomeCubit extends Cubit<HomeState> {
  final SessionCubit _sessionCubit;
  final RideRequestRepository _repository;

  HomeCubit(this._sessionCubit, this._repository) : super(HomeState.initial());

  /// Called when the screen first loads.
  void initialize() {
    if (isClosed) return;
    final user = _sessionCubit.state;
    emit(state.copyWith(userName: user?.firstName));
  }

  /// Updates the greeting based on the current time of day.
  void refreshGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    if (!isClosed && state.greeting != greeting) {
      emit(state.copyWith(greeting: greeting));
    }
  }

  void setFromLocation(PickedLocationModel location) {
    if (!isClosed) emit(state.copyWith(fromLocation: location));
  }

  void setToLocation(PickedLocationModel location) {
    if (!isClosed) emit(state.copyWith(toLocation: location));
  }

  Future<void> searchRide() async {
    final from = state.fromLocation;
    final to = state.toLocation;
    if (!state.canSearch || from == null || to == null || isClosed) return;

    emit(state.copyWith(isSearching: true, clearSearchError: true));
    try {
      await _repository.searchRide(from: from, to: to);
      if (isClosed) return;
      // TODO: backend search/matching endpoint doesn't exist yet — once it
      // does, decide what happens next here (e.g. navigate to a
      // driver-matching/tracking screen).
      emit(state.copyWith(isSearching: false));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSearching: false, searchErrorMessage: e.message));
    }
  }
}
