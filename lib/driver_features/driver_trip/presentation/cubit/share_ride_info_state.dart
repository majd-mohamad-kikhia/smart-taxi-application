import 'package:equatable/equatable.dart';

class ShareRideInfoState extends Equatable {
  final bool isSharing;

  /// Why the last attempt failed; [failureCount] grows with every failure so
  /// the same message can be shown again.
  final String? errorMessage;
  final int failureCount;

  const ShareRideInfoState({this.isSharing = false, this.errorMessage, this.failureCount = 0});

  @override
  List<Object?> get props => [isSharing, errorMessage, failureCount];
}
