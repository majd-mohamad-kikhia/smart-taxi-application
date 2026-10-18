import 'package:equatable/equatable.dart';

/// Which of the driver's two photos is being changed.
enum DriverPhotoTarget { personal, vehicle }

class DriverPhotoState extends Equatable {
  /// The photo being uploaded now; null when none is.
  final DriverPhotoTarget? uploading;

  /// Why the last change failed; cleared when the next one starts.
  final String? errorMessage;

  const DriverPhotoState({this.uploading, this.errorMessage});

  @override
  List<Object?> get props => [uploading, errorMessage];
}
