import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/driver_complaints_repository.dart';
import 'driver_complaint_state.dart';

/// Drives the driver complaint dialog — submits to
/// `POST /api/driver/complaints`.
class DriverComplaintCubit extends Cubit<DriverComplaintState> {
  final DriverComplaintsRepository _repository;

  DriverComplaintCubit(this._repository) : super(const DriverComplaintState());

  Future<void> submit({required String message, String? subject}) async {
    emit(
      state.copyWith(submitStatus: ComplaintSubmitStatus.submitting, clearError: true),
    );
    try {
      await _repository.submitComplaint(message: message, subject: subject);
      if (isClosed) return;
      emit(state.copyWith(submitStatus: ComplaintSubmitStatus.success));
    } on DriverComplaintsException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          submitStatus: ComplaintSubmitStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }
}
