import 'package:flutter_bloc/flutter_bloc.dart';
import 'complaint_exception.dart';
import 'complaint_state.dart';

/// Sends a complaint to whichever role-specific endpoint backs it.
typedef ComplaintSubmitter =
    Future<void> Function({required String message, String? subject});

/// Drives the shared complaint dialog. Each role (customer / driver)
/// registers its own instance with its own [ComplaintSubmitter].
class ComplaintCubit extends Cubit<ComplaintState> {
  final ComplaintSubmitter _submitter;

  ComplaintCubit(this._submitter) : super(const ComplaintState());

  Future<void> submit({required String message, String? subject}) async {
    emit(
      state.copyWith(
        submitStatus: ComplaintSubmitStatus.submitting,
        clearError: true,
      ),
    );
    try {
      await _submitter(message: message, subject: subject);
      if (isClosed) return;
      emit(state.copyWith(submitStatus: ComplaintSubmitStatus.success));
    } on ComplaintException catch (e) {
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
