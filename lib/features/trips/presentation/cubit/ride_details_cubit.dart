import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ride_history_model.dart';
import '../../data/repositories/trips_repository.dart';

class RideDetailsState extends Equatable {
  final RideHistoryModel? ride;
  final bool isLoading;
  final String? errorMessage;

  const RideDetailsState({
    this.ride,
    this.isLoading = true,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [ride, isLoading, errorMessage];
}

/// Loads a single ride (`GET /api/customer/rides/{id}`), with a simplified
/// driven route for the details map.
class RideDetailsCubit extends Cubit<RideDetailsState> {
  final TripsRepository _repository;
  final int rideId;

  RideDetailsCubit(this._repository, {required this.rideId})
      : super(const RideDetailsState());

  Future<void> load() async {
    emit(const RideDetailsState());
    try {
      final ride = await _repository.getRide(rideId, simplify: true);
      if (isClosed) return;
      emit(RideDetailsState(ride: ride, isLoading: false));
    } on TripsException catch (e) {
      if (isClosed) return;
      emit(RideDetailsState(isLoading: false, errorMessage: e.message));
    }
  }
}
