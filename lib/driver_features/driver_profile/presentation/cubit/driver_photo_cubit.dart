import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../driver_auth/data/repositories/driver_repository.dart';
import '../../../driver_auth/presentation/cubit/driver_auth_cubit.dart';
import 'driver_photo_state.dart';

/// Changes the driver's own personal photo or car photo from the profile:
/// `PUT /api/driver/profile`. Saves through [DriverAuthCubit], the single
/// owner of the driver, so the new photo shows everywhere at once.
class DriverPhotoCubit extends Cubit<DriverPhotoState> {
  final DriverAuthCubit _driverAuthCubit;
  final PhotoPickerService _photos;

  DriverPhotoCubit(this._driverAuthCubit, this._photos)
    : super(const DriverPhotoState());

  /// Opens the camera or gallery and uploads the chosen photo as the
  /// driver's own.
  Future<void> changePersonal(PhotoSource source) =>
      _change(DriverPhotoTarget.personal, source);

  /// Opens the camera or gallery and uploads the chosen photo as the car's.
  Future<void> changeVehicle(PhotoSource source) =>
      _change(DriverPhotoTarget.vehicle, source);

  Future<void> _change(DriverPhotoTarget target, PhotoSource source) async {
    if (isClosed || state.uploading != null) return;
    final picked = await _photos.pick(source);
    if (isClosed || picked == null) return;
    if (picked.tooLarge) {
      emit(DriverPhotoState(errorMessage: AppStrings.current.driverSignupPhotoTooLarge));
      return;
    }
    emit(DriverPhotoState(uploading: target));
    try {
      await _driverAuthCubit.updatePhotos(
        photoPath: target == DriverPhotoTarget.personal ? picked.path : null,
        vehiclePhotoPath: target == DriverPhotoTarget.vehicle ? picked.path : null,
      );
      if (!isClosed) emit(const DriverPhotoState());
    } on DriverAuthException catch (e) {
      if (!isClosed) emit(DriverPhotoState(errorMessage: e.message));
    }
  }
}
