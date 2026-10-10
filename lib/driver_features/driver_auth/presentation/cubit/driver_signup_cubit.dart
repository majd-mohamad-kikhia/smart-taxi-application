import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/status_code.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../data/models/driver_signup_request_model.dart';
import '../../data/repositories/driver_repository.dart';
import 'driver_signup_state.dart';

/// The typed text of the signup form, handed over on submit.
typedef DriverSignupTexts = ({
  String firstName,
  String lastName,
  String phone,
  String password,
  String address,
  String brand,
  String model,
  String color,
  String plateNumber,
});

/// Drives the driver's self-signup: the car type, ownership and the two
/// photos, then the multipart request. A new account is pending until a
/// manager approves it, so success never signs the driver in.
class DriverSignupCubit extends Cubit<DriverSignupState> {
  final DriverRepository _repository;
  final PhotoPickerService _photos;

  DriverSignupCubit(this._repository, this._photos)
    : super(const DriverSignupState());

  /// Asks the server for the active car types (each time the screen opens
  /// and on Retry). There is no fixed list to fall back to.
  Future<void> loadVehicleTypes() async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingTypes: true, clearTypesError: true));
    try {
      final types = await _repository.signupVehicleTypes();
      if (isClosed) return;
      // A choice the server no longer offers is dropped.
      final stillThere = types.any((t) => t.id == state.vehicleTypeId);
      emit(state.copyWith(
        isLoadingTypes: false,
        vehicleTypes: types,
        clearVehicleType: !stillThere,
      ));
    } on DriverSignupException catch (e) {
      if (!isClosed) emit(state.copyWith(isLoadingTypes: false, typesError: e.message));
    }
  }

  void selectVehicleType(int id) {
    if (isClosed || state.isSubmitting) return;
    emit(state.copyWith(vehicleTypeId: id));
  }

  void selectOwnership(VehicleOwnership ownership) {
    if (isClosed || state.isSubmitting) return;
    emit(state.copyWith(ownership: ownership));
  }

  /// Opens the camera or gallery for the personal photo.
  Future<void> pickPhoto(PhotoSource source) async {
    final picked = await _photos.pick(source);
    if (isClosed || picked == null) return;
    emit(picked.tooLarge
        ? state.copyWith(photoError: AppStrings.current.driverSignupPhotoTooLarge)
        : state.copyWith(photoPath: picked.path, clearPhotoError: true));
  }

  /// Opens the camera or gallery for the car photo.
  Future<void> pickVehiclePhoto(PhotoSource source) async {
    final picked = await _photos.pick(source);
    if (isClosed || picked == null) return;
    emit(picked.tooLarge
        ? state.copyWith(vehiclePhotoError: AppStrings.current.driverSignupPhotoTooLarge)
        : state.copyWith(vehiclePhotoPath: picked.path, clearVehiclePhotoError: true));
  }

  /// The form has errors: also show which car type or photo is missing, so
  /// everything to fix is visible at once.
  void showMissingChoices() {
    if (isClosed || state.isSubmitting) return;
    emit(state.copyWith(submitAttempted: true, clearErrors: true));
  }

  /// Sends the form. The text fields were already validated by the form;
  /// the car type and photos are checked here.
  Future<void> submit(DriverSignupTexts texts) async {
    if (isClosed || state.isSubmitting) return;
    final vehicleTypeId = state.vehicleTypeId;
    final photo = state.photoPath;
    final vehiclePhoto = state.vehiclePhotoPath;
    if (vehicleTypeId == null || photo == null || vehiclePhoto == null) {
      emit(state.copyWith(submitAttempted: true, clearErrors: true));
      return;
    }
    emit(state.copyWith(
      status: DriverSignupStatus.submitting,
      submitAttempted: true,
      clearErrors: true,
    ));
    try {
      await _repository.signup(DriverSignupRequestModel(
        firstName: texts.firstName,
        lastName: texts.lastName,
        phone: texts.phone,
        password: texts.password,
        address: texts.address.isEmpty ? null : texts.address,
        vehicleTypeId: vehicleTypeId,
        brand: texts.brand,
        model: texts.model,
        color: texts.color,
        plateNumber: texts.plateNumber,
        ownership: state.ownership,
        photoPath: photo,
        vehiclePhotoPath: vehiclePhoto,
      ));
      if (!isClosed) emit(state.copyWith(status: DriverSignupStatus.success));
    } on DriverSignupException catch (e) {
      if (isClosed) return;
      final l10n = AppStrings.current;
      final isConflict = e.statusCode == StatusCode.conflict;
      emit(state.copyWith(
        status: DriverSignupStatus.editing,
        // 409 names the field that is taken; say which, in the field.
        phoneError: isConflict && e.rawErrors.containsKey('phone_number')
            ? l10n.errPhoneRegistered
            : null,
        plateError: isConflict && e.rawErrors.containsKey('plate_number')
            ? l10n.driverSignupPlateRegistered
            : null,
        errorMessage: isConflict &&
                (e.rawErrors.containsKey('phone_number') ||
                    e.rawErrors.containsKey('plate_number'))
            ? null
            : e.message,
      ));
    }
  }
}
