import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/driver_user_model.dart';

enum DriverAuthStatus { idle, submitting, success, failure }

class DriverAuthState extends Equatable {
  final DriverAuthStatus status;
  final DriverUserModel? driver;
  final String? errorMessage;

  /// The wallet balance as of the last time the server was asked (at sign in,
  /// or by `refreshWalletBalance`); null while it isn't known. Deliberately
  /// not `driver.walletBalance`, which is the copy saved at sign in and
  /// restored on every start — days old, so wrong after any top-up.
  final double? walletBalance;

  const DriverAuthState({
    this.status = DriverAuthStatus.idle,
    this.driver,
    this.errorMessage,
    this.walletBalance,
  });

  /// The known balance is at or below what accepting an order needs
  /// ([AppConstants.lowDriverWalletBalance]).
  bool get isWalletLow =>
      walletBalance != null && walletBalance! <= AppConstants.lowDriverWalletBalance;

  factory DriverAuthState.initial() => const DriverAuthState();

  DriverAuthState copyWith({
    DriverAuthStatus? status,
    DriverUserModel? driver,
    String? errorMessage,
    bool clearError = false,
    double? walletBalance,
  }) {
    return DriverAuthState(
      status: status ?? this.status,
      driver: driver ?? this.driver,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  @override
  List<Object?> get props => [status, driver, errorMessage, walletBalance];
}
