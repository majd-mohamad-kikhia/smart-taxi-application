import 'package:equatable/equatable.dart';

class CallCustomerState extends Equatable {
  final bool isCalling;

  /// Why the last attempt failed; [failureCount] grows with every failure so
  /// the same message can be shown again.
  final String? errorMessage;
  final int failureCount;

  const CallCustomerState({
    this.isCalling = false,
    this.errorMessage,
    this.failureCount = 0,
  });

  @override
  List<Object?> get props => [isCalling, errorMessage, failureCount];
}
