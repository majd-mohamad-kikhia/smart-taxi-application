import 'package:equatable/equatable.dart';
import '../../data/models/driver_deletion_request_model.dart';

/// Immutable state for the driver's account-deletion request: the latest
/// request plus the progress/error of each of its three actions.
class DriverAccountDeletionState extends Equatable {
  /// The latest request; `null` when the driver never asked, or after
  /// cancelling (both look the same to the UI).
  final DriverDeletionRequestModel? request;
  final bool isLoading;
  final String? loadError;
  final bool isSubmitting;

  /// Failure of the request form (e.g. wrong password), shown in the dialog.
  final String? submitError;
  final bool isCancelling;

  /// Failure of "cancel request", shown as a snackbar.
  final String? actionError;

  const DriverAccountDeletionState({
    this.request,
    this.isLoading = true,
    this.loadError,
    this.isSubmitting = false,
    this.submitError,
    this.isCancelling = false,
    this.actionError,
  });

  DriverAccountDeletionState copyWith({
    DriverDeletionRequestModel? request,
    bool clearRequest = false,
    bool? isLoading,
    String? loadError,
    bool? isSubmitting,
    String? submitError,
    bool? isCancelling,
    String? actionError,
    bool clearLoadError = false,
    bool clearSubmitError = false,
    bool clearActionError = false,
  }) {
    return DriverAccountDeletionState(
      request: clearRequest ? null : (request ?? this.request),
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isCancelling: isCancelling ?? this.isCancelling,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    request,
    isLoading,
    loadError,
    isSubmitting,
    submitError,
    isCancelling,
    actionError,
  ];
}
