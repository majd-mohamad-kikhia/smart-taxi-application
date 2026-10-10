import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ride_rating_repository.dart';
import 'ride_rating_state.dart';

/// Drives the "rate your driver" dialog for one completed trip.
class RideRatingCubit extends Cubit<RideRatingState> {
  final RideRatingRepository _repository;
  final int rideId;

  RideRatingCubit(this._repository, {required this.rideId})
    : super(const RideRatingState());

  void selectStars(int stars) {
    if (isClosed || state.isSending || stars < 1 || stars > 5) return;
    emit(state.copyWith(stars: stars, clearError: true));
  }

  Future<void> send(String comment) async {
    if (isClosed || !state.canSend || state.status == RideRatingStatus.sent) return;
    emit(state.copyWith(status: RideRatingStatus.sending, clearError: true));
    try {
      final saved = await _repository.rateRide(
        rideId: rideId,
        stars: state.stars,
        comment: comment.trim(),
      );
      if (!isClosed) {
        emit(state.copyWith(status: RideRatingStatus.sent, saved: saved));
      }
    } on RideRatingException catch (e) {
      if (isClosed) return;
      emit(
        e.isAlreadyRated
            ? state.copyWith(status: RideRatingStatus.alreadyRated, errorMessage: e.message)
            : state.copyWith(status: RideRatingStatus.editing, errorMessage: e.message),
      );
    }
  }
}
