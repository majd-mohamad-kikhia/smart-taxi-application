import 'package:equatable/equatable.dart';
import '../../data/models/ride_rating_model.dart';

enum RideRatingStatus { editing, sending, sent, alreadyRated }

class RideRatingState extends Equatable {
  /// 0 until the customer picks a star.
  final int stars;
  final RideRatingStatus status;
  final String? errorMessage;

  /// What the server stored, once [status] is [RideRatingStatus.sent].
  final RideRatingModel? saved;

  const RideRatingState({
    this.stars = 0,
    this.status = RideRatingStatus.editing,
    this.errorMessage,
    this.saved,
  });

  bool get isSending => status == RideRatingStatus.sending;

  /// Send is available once a star is picked, and not while sending.
  bool get canSend => stars >= 1 && !isSending;

  RideRatingState copyWith({
    int? stars,
    RideRatingStatus? status,
    String? errorMessage,
    bool clearError = false,
    RideRatingModel? saved,
  }) => RideRatingState(
    stars: stars ?? this.stars,
    status: status ?? this.status,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [stars, status, errorMessage, saved];
}
