import 'package:equatable/equatable.dart';
import '../../data/models/driver_user_model.dart';

enum DriverAuthStatus { idle, submitting, success, failure }

class DriverAuthState extends Equatable {
  final DriverAuthStatus status;
  final DriverUserModel? driver;
  final String? errorMessage;

  const DriverAuthState({
    this.status = DriverAuthStatus.idle,
    this.driver,
    this.errorMessage,
  });

  factory DriverAuthState.initial() => const DriverAuthState();

  DriverAuthState copyWith({
    DriverAuthStatus? status,
    DriverUserModel? driver,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverAuthState(
      status: status ?? this.status,
      driver: driver ?? this.driver,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, driver, errorMessage];
}
