import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role.dart';
import 'terms_repository.dart';
import 'terms_state.dart';

/// Loads the terms and conditions for the terms dialog — shared by the
/// rider sign-up screen and both roles' settings screens.
class TermsCubit extends Cubit<TermsState> {
  final TermsRepository _repository;

  TermsCubit(this._repository) : super(const TermsState());

  Future<void> load(UserRole role, String languageCode) async {
    emit(const TermsState());
    try {
      final terms = await _repository.getTerms(role, languageCode);
      if (isClosed) return;
      emit(TermsState(status: TermsLoadStatus.success, terms: terms));
    } on TermsException catch (e) {
      if (isClosed) return;
      emit(TermsState(status: TermsLoadStatus.failure, errorMessage: e.message));
    }
  }
}
