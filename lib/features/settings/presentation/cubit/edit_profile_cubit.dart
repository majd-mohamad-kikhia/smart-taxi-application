import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/session/app_user.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/models/customer_profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'edit_profile_state.dart';

/// Loads the customer's profile and saves edits via `PUT /api/customer/profile`.
class EditProfileCubit extends Cubit<EditProfileState> {
  final ProfileRepository _repository;
  final SessionCubit _sessionCubit;

  EditProfileCubit(this._repository, this._sessionCubit)
    : super(const EditProfileState());

  Future<void> load() async {
    emit(const EditProfileState());
    try {
      final profile = await _repository.getProfile();
      if (isClosed) return;
      emit(
        EditProfileState(status: EditProfileStatus.loaded, profile: profile),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        EditProfileState(
          status: EditProfileStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  /// Sends only the fields that differ from the loaded profile.
  Future<void> save({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String address,
  }) async {
    final current = state.profile;
    if (current == null || state.status == EditProfileStatus.saving) return;

    final changes = <String, dynamic>{
      if (firstName != current.firstName) 'first_name': firstName,
      if (lastName != current.lastName) 'last_name': lastName,
      if (phone != current.phone) 'phone_number': phone,
      if (email != (current.email ?? '')) 'email': email,
      if (address != (current.address ?? '')) 'address': address,
    };
    if (changes.isEmpty) {
      emit(state.copyWith(status: EditProfileStatus.saved));
      return;
    }

    emit(state.copyWith(status: EditProfileStatus.saving));
    try {
      final updated = await _repository.updateProfile(changes);
      if (isClosed) return;
      _publishToSession(updated);
      emit(state.copyWith(status: EditProfileStatus.saved, profile: updated));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: EditProfileStatus.loaded,
          errorMessage: e.message,
          fieldErrors: e.fieldErrors,
        ),
      );
    }
  }

  void _publishToSession(CustomerProfileModel profile) {
    final user = _sessionCubit.state;
    if (user == null) return;
    _sessionCubit.setUser(
      AppUser(
        id: user.id,
        fullName: profile.fullName,
        phone: profile.phone,
        email: profile.email,
        photoUrl: profile.photoUrl,
        role: user.role,
      ),
    );
  }
}
