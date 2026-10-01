import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/status_code.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/repositories/profile_repository.dart';
import 'delete_account_state.dart';

/// Drives the customer's "delete my account" dialog: asks the server to
/// delete the account (confirmed with the password), then signs this device
/// out locally.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final ProfileRepository _repository;
  final SessionCubit _sessionCubit;

  DeleteAccountCubit(this._repository, this._sessionCubit)
    : super(const DeleteAccountState.initial());

  Future<void> submit(String password) async {
    if (isClosed || state.isSubmitting) return;
    emit(const DeleteAccountState(status: DeleteAccountStatus.submitting));
    try {
      await _repository.deleteAccount(password);
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          DeleteAccountState(
            status: DeleteAccountStatus.failure,
            errorMessage: _messageFor(e),
          ),
        );
      }
      return;
    }
    // The account is gone and the server has signed every device out.
    // Logging out clears this device's tokens and saved session; its own
    // call to the server fails harmlessly (the token no longer works).
    await _sessionCubit.logout();
    if (!isClosed) {
      emit(const DeleteAccountState(status: DeleteAccountStatus.success));
    }
  }

  /// A wrong password (401) and an active ride (409) are the two failures
  /// the user can act on, so they get their own wording.
  String _messageFor(ApiException e) {
    final l10n = AppStrings.current;
    return switch (e.statusCode) {
      StatusCode.unauthorized => l10n.errIncorrectPassword,
      StatusCode.conflict => l10n.errDeleteActiveRide,
      _ => e.message,
    };
  }
}
