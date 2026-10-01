import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../../data/repositories/driver_account_deletion_repository.dart';
import 'driver_account_deletion_state.dart';

/// Drives the driver's account-deletion request: shows the latest one,
/// sends a new one (confirmed with the password) and cancels a pending one.
/// The driver keeps working until a manager approves, so nothing here
/// signs the driver out.
class DriverAccountDeletionCubit extends Cubit<DriverAccountDeletionState> {
  final DriverAccountDeletionRepository _repository;

  DriverAccountDeletionCubit(this._repository)
    : super(const DriverAccountDeletionState());

  /// Forgets the last submit error, so reopening the dialog starts clean.
  void clearSubmitError() {
    if (isClosed || state.submitError == null) return;
    emit(state.copyWith(clearSubmitError: true));
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearLoadError: true));
    try {
      final request = await _repository.getLatestRequest();
      if (isClosed) return;
      emit(
        request == null
            ? state.copyWith(isLoading: false, clearRequest: true)
            : state.copyWith(isLoading: false, request: request),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, loadError: _messageOf(e)));
    }
  }

  Future<void> submit(String password, String reason) async {
    if (isClosed || state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final request = await _repository.requestDeletion(
        password: password,
        reason: reason.trim(),
      );
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, request: request));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, submitError: _submitMessage(e)));
    }
  }

  Future<void> cancel() async {
    if (isClosed || state.isCancelling) return;
    emit(state.copyWith(isCancelling: true, clearActionError: true));
    try {
      await _repository.cancelRequest();
      if (isClosed) return;
      emit(state.copyWith(isCancelling: false, clearRequest: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isCancelling: false, actionError: _messageOf(e)));
      // 404: nothing pending any more (a manager already decided) — show
      // the up-to-date status instead of a stale "under review" card.
      if (e is ApiException && e.statusCode == StatusCode.notFound) {
        await load();
      }
    }
  }

  /// A wrong password (401) is the failure the driver can act on.
  String _submitMessage(Object error) {
    if (error is ApiException && error.statusCode == StatusCode.unauthorized) {
      return AppStrings.current.errIncorrectPassword;
    }
    return _messageOf(error);
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : AppStrings.current.errUnexpected;
}
