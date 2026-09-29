import 'package:equatable/equatable.dart';
import '../../data/models/customer_profile_model.dart';

enum EditProfileStatus { loading, loaded, saving, saved, failure }

/// Immutable state for the edit-profile screen.
class EditProfileState extends Equatable {
  final EditProfileStatus status;
  final CustomerProfileModel? profile;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const EditProfileState({
    this.status = EditProfileStatus.loading,
    this.profile,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  EditProfileState copyWith({
    EditProfileStatus? status,
    CustomerProfileModel? profile,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, fieldErrors];
}
