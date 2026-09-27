import 'package:flutter_bloc/flutter_bloc.dart';
import 'tracking_state.dart';

/// Cubit managing the Live Trip Tracking screen state.
class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit() : super(TrackingState.initial());

  void initialize() {
    if (!isClosed) emit(TrackingState.initial());
  }

  Future<void> cancelTrip() async {
    if (isClosed || state.isCancelling) return;
    emit(state.copyWith(isCancelling: true));

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!isClosed) {
      emit(state.copyWith(isCancelling: false, isCancelled: true));
    }
  }

  void callCaptain() {
    // Placeholder – wire to dialer / VoIP in later iterations
  }

  void openChat() {
    // Placeholder – navigate to chat screen later
  }

  void shareTrip() {
    // Placeholder – share live location link later
  }
}
