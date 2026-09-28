import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/picked_location_model.dart';
import '../../data/repositories/ride_request_repository.dart';
import 'home_state.dart';

/// Cubit driving the "إنشاء طلب" (create request) order flow:
/// pick two points → resolve a price quote per vehicle type → choose a
/// vehicle (which creates the ride) → cancel it.
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
    if (isClosed) return;
    // Any previous quote priced a different trip.
    emit(state.copyWith(fromLocation: location, clearQuote: true));
  }

  void setToLocation(PickedLocationModel location) {
    if (isClosed) return;
    emit(state.copyWith(toLocation: location, clearQuote: true));
  }

  /// Order flow step 1 — resolves the two pins into distance, ETA and a
  /// price per vehicle type. The screen opens the vehicle sheet when
  /// [HomeState.quote] arrives.
  Future<void> searchRide() async {
    final from = state.fromLocation;
    final to = state.toLocation;
    if (!state.canSearch || from == null || to == null || isClosed) return;

    emit(state.copyWith(isSearching: true, clearError: true, clearQuote: true));
    try {
      final quote = await _repository.resolveLocations(
        pickup: from,
        dropoff: to,
      );
      if (isClosed) return;
      emit(state.copyWith(isSearching: false, quote: quote));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSearching: false, errorMessage: e.message));
    }
  }

  /// Order flow step 2 — creates the ride with the chosen vehicle type.
  Future<void> chooseVehicle(int vehicleTypeId) async {
    final from = state.fromLocation;
    final to = state.toLocation;
    if (from == null || to == null || isClosed) return;

    emit(state.copyWith(isBooking: true, clearError: true));
    try {
      final ride = await _repository.chooseVehicle(
        vehicleTypeId: vehicleTypeId,
        pickup: from,
        dropoff: to,
      );
      if (isClosed) return;
      emit(state.copyWith(isBooking: false, activeRide: ride));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isBooking: false, errorMessage: e.message));
    }
  }

  Future<void> cancelRide() async {
    final ride = state.activeRide;
    if (ride == null || isClosed) return;

    emit(state.copyWith(isCancelling: true, clearError: true));
    try {
      await _repository.cancelRide(rideId: ride.id);
      if (isClosed) return;
      emit(state.copyWith(
        isCancelling: false,
        clearActiveRide: true,
        clearQuote: true,
      ));
    } on RideRequestException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isCancelling: false, errorMessage: e.message));
    }
  }
}
