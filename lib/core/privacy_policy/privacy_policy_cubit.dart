import 'package:flutter_bloc/flutter_bloc.dart';
import 'privacy_policy_repository.dart';
import 'privacy_policy_state.dart';

/// Loads the privacy policy for its dialog — shared by the customer sign-up
/// screen and both roles' settings screens.
class PrivacyPolicyCubit extends Cubit<PrivacyPolicyState> {
  final PrivacyPolicyRepository _repository;

  PrivacyPolicyCubit(this._repository) : super(const PrivacyPolicyState());

  Future<void> load(String languageCode) async {
    emit(const PrivacyPolicyState());
    try {
      final policy = await _repository.getPrivacyPolicy(languageCode);
      if (isClosed) return;
      emit(
        PrivacyPolicyState(
          status: PrivacyPolicyLoadStatus.success,
          policy: policy,
        ),
      );
    } on PrivacyPolicyException catch (e) {
      if (isClosed) return;
      emit(
        PrivacyPolicyState(
          status: PrivacyPolicyLoadStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }
}
