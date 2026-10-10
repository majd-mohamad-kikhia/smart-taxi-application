import 'package:equatable/equatable.dart';
import '../../data/models/driver_signup_request_model.dart';

enum DriverSignupStatus { editing, submitting, success }

/// The signup form's choices (car type, ownership, the two photos) and how
/// the last submit went. The typed text lives in the form's controllers.
class DriverSignupState extends Equatable {
  final DriverSignupStatus status;
  /// The server's active car types; empty until loaded.
  final List<SignupVehicleType> vehicleTypes;
  final bool isLoadingTypes;
  final String? typesError;
  final int? vehicleTypeId;
  final VehicleOwnership ownership;
  final String? photoPath;
  final String? vehiclePhotoPath;

  /// A submit was tried: the missing choices and photos now show as errors.
  final bool submitAttempted;

  /// The reason a chosen photo can't be used (too large).
  final String? photoError;
  final String? vehiclePhotoError;

  /// For the whole form (network, unknown refusal).
  final String? errorMessage;

  /// What the server said about single fields.
  final String? phoneError;
  final String? plateError;

  const DriverSignupState({
    this.status = DriverSignupStatus.editing,
    this.vehicleTypes = const [],
    this.isLoadingTypes = true,
    this.typesError,
    this.vehicleTypeId,
    this.ownership = VehicleOwnership.owner,
    this.photoPath,
    this.vehiclePhotoPath,
    this.submitAttempted = false,
    this.photoError,
    this.vehiclePhotoError,
    this.errorMessage,
    this.phoneError,
    this.plateError,
  });

  bool get isSubmitting => status == DriverSignupStatus.submitting;
  bool get vehicleTypeMissing => submitAttempted && vehicleTypeId == null;
  bool get photoMissing => submitAttempted && photoPath == null;
  bool get vehiclePhotoMissing => submitAttempted && vehiclePhotoPath == null;

  DriverSignupState copyWith({
    DriverSignupStatus? status,
    List<SignupVehicleType>? vehicleTypes,
    bool? isLoadingTypes,
    String? typesError,
    bool clearTypesError = false,
    bool clearVehicleType = false,
    int? vehicleTypeId,
    VehicleOwnership? ownership,
    String? photoPath,
    String? vehiclePhotoPath,
    bool? submitAttempted,
    String? photoError,
    String? vehiclePhotoError,
    String? errorMessage,
    String? phoneError,
    String? plateError,
    bool clearPhotoError = false,
    bool clearVehiclePhotoError = false,
    bool clearErrors = false,
  }) => DriverSignupState(
    status: status ?? this.status,
    vehicleTypes: vehicleTypes ?? this.vehicleTypes,
    isLoadingTypes: isLoadingTypes ?? this.isLoadingTypes,
    typesError: clearTypesError ? null : (typesError ?? this.typesError),
    vehicleTypeId: clearVehicleType ? null : (vehicleTypeId ?? this.vehicleTypeId),
    ownership: ownership ?? this.ownership,
    photoPath: photoPath ?? this.photoPath,
    vehiclePhotoPath: vehiclePhotoPath ?? this.vehiclePhotoPath,
    submitAttempted: submitAttempted ?? this.submitAttempted,
    photoError: clearPhotoError ? null : (photoError ?? this.photoError),
    vehiclePhotoError: clearVehiclePhotoError
        ? null
        : (vehiclePhotoError ?? this.vehiclePhotoError),
    errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    phoneError: clearErrors ? null : (phoneError ?? this.phoneError),
    plateError: clearErrors ? null : (plateError ?? this.plateError),
  );

  @override
  List<Object?> get props => [
    status,
    vehicleTypes,
    isLoadingTypes,
    typesError,
    vehicleTypeId,
    ownership,
    photoPath,
    vehiclePhotoPath,
    submitAttempted,
    photoError,
    vehiclePhotoError,
    errorMessage,
    phoneError,
    plateError,
  ];
}
