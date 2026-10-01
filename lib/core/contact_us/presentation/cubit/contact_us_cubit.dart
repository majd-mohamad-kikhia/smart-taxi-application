import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../network/api_exception.dart';
import '../../data/repositories/contact_us_repository.dart';
import 'contact_us_state.dart';

/// Loads the "Contact us" numbers for the screen — shared by both roles.
class ContactUsCubit extends Cubit<ContactUsState> {
  final ContactUsRepository _repository;

  ContactUsCubit(this._repository) : super(const ContactUsLoading());

  /// A refresh on top of a list already on screen keeps it, and a failed
  /// refresh leaves it in place (no error flash). Equal lists (a `304`) are
  /// not re-emitted.
  Future<void> load({required String lang}) async {
    final current = state;
    if (current is! ContactUsLoaded) emit(const ContactUsLoading());
    try {
      final numbers = await _repository.getContactNumbers(lang: lang);
      if (isClosed) return;
      emit(ContactUsLoaded(numbers));
    } on ApiException catch (e) {
      if (isClosed) return;
      if (current is! ContactUsLoaded) emit(ContactUsError(e.message));
    }
  }
}
