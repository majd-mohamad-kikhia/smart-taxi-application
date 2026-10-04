import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ride_history_model.dart';
import '../../data/repositories/trips_repository.dart';

class RideDetailsState extends Equatable {
  final RideHistoryModel? ride;
  final bool isLoading;
  final String? errorMessage;

  /// Cancelling a scheduled ride is in flight.
  final bool isCancelling;

  /// Why the last cancel failed, shown once as a message.
  final String? actionError;

  const RideDetailsState({
    this.ride,
    this.isLoading = true,
    this.errorMessage,
    this.isCancelling = false,
    this.actionError,
  });

  @override
  List<Object?> get props =>
      [ride, isLoading, errorMessage, isCancelling, actionError];
}

/// Loads a single ride (`GET /api/customer/rides/{id}`), with a simplified
/// driven route for the details map, and cancels it while it is scheduled.
class RideDetailsCubit extends Cubit<RideDetailsState> {
  final TripsRepository _repository;
  final int rideId;

  RideDetailsCubit(this._repository, {required this.rideId})
      : super(const RideDetailsState());

  Future<void> load() async {
    emit(RideDetailsState(ride: state.ride));
    try {
      final ride = await _repository.getRide(rideId, simplify: true);
      if (isClosed) return;
      emit(RideDetailsState(ride: ride, isLoading: false));
    } on TripsException catch (e) {
      if (isClosed) return;
      emit(RideDetailsState(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> cancelScheduled({String? reason}) async {
    final ride = state.ride;
    if (isClosed || ride == null || !ride.isScheduled || state.isCancelling) return;
    emit(RideDetailsState(ride: ride, isLoading: false, isCancelling: true));
    try {
      await _repository.cancelRide(rideId, cancellationReason: reason);
      if (isClosed) return;
      await load();
    } on TripsException catch (e) {
      if (isClosed) return;
      emit(RideDetailsState(ride: ride, isLoading: false, actionError: e.message));
    }
  }
}
