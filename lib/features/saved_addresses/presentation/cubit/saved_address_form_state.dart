import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';

enum SavedAddressFormStatus { editing, saving, saved }

class SavedAddressFormState extends Equatable {
  final PickedLocationModel? location;
  final SavedAddressFormStatus status;

  /// The save replaced the customer's previous home / work.
  final bool replaced;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const SavedAddressFormState({
    this.location,
    this.status = SavedAddressFormStatus.editing,
    this.replaced = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isSaving => status == SavedAddressFormStatus.saving;

  SavedAddressFormState copyWith({
    PickedLocationModel? location,
    SavedAddressFormStatus? status,
    bool? replaced,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool clearErrors = false,
  }) {
    return SavedAddressFormState(
      location: location ?? this.location,
      status: status ?? this.status,
      replaced: replaced ?? this.replaced,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearErrors ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }

  @override
  List<Object?> get props =>
      [location, status, replaced, errorMessage, fieldErrors];
}
