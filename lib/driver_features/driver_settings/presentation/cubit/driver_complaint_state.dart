import 'package:equatable/equatable.dart';

enum ComplaintSubmitStatus { idle, submitting, success, failure }

/// Immutable state for the driver complaint dialog.
class DriverComplaintState extends Equatable {
  final ComplaintSubmitStatus submitStatus;
  final String? errorMessage;

  const DriverComplaintState({
    this.submitStatus = ComplaintSubmitStatus.idle,
    this.errorMessage,
  });

  DriverComplaintState copyWith({
    ComplaintSubmitStatus? submitStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverComplaintState(
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [submitStatus, errorMessage];
}
