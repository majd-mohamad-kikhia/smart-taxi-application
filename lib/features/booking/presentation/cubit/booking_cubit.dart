import 'package:flutter_bloc/flutter_bloc.dart';
import 'booking_state.dart';

/// Cubit managing the Booking / Confirm Ride screen state.
class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingState.initial());

  void initialize() {
    if (!isClosed) emit(BookingState.initial());
  }

  void selectCategory(String categoryId) {
    if (isClosed || state.selectedCategoryId == categoryId) return;
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  void swapRoute() {
    if (isClosed) return;
    emit(state.copyWith(route: state.route.swap()));
  }

  void updateCaptainNote(String note) {
    if (isClosed) return;
    emit(state.copyWith(captainNote: note));
  }

  Future<void> confirmBooking() async {
    if (isClosed || state.isConfirming) return;
    emit(state.copyWith(isConfirming: true));

    // Simulate network confirmation latency
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!isClosed) {
      emit(state.copyWith(isConfirming: false, isConfirmed: true));
    }
  }
}
