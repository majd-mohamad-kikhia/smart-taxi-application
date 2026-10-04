import 'package:equatable/equatable.dart';

class RideBillState extends Equatable {
  final bool isSending;

  /// Why the last send failed; [failureCount] grows with every failure so
  /// the same message can be shown again.
  final String? errorMessage;
  final int failureCount;

  const RideBillState({this.isSending = false, this.errorMessage, this.failureCount = 0});

  @override
  List<Object?> get props => [isSending, errorMessage, failureCount];
}
