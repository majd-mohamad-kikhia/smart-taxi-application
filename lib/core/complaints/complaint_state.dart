import 'package:equatable/equatable.dart';

enum ComplaintSubmitStatus { idle, submitting, success, failure }

/// Immutable state for the complaint dialog.
class ComplaintState extends Equatable {
  final ComplaintSubmitStatus submitStatus;
  final String? errorMessage;

  const ComplaintState({
    this.submitStatus = ComplaintSubmitStatus.idle,
    this.errorMessage,
  });

  ComplaintState copyWith({
    ComplaintSubmitStatus? submitStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ComplaintState(
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [submitStatus, errorMessage];
}
