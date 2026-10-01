import 'package:equatable/equatable.dart';

/// The `ride.payment` block returned by
/// `POST /api/driver/rides/{id}/confirm-payment`: how the cash paid by the
/// customer was split, and the driver's wallet after the commission
/// deduction.
class DriverTripPaymentModel extends Equatable {
  final double totalPaid;
  final double driverShare;
  final double managerShare;
  final double commissionRate;
  final double walletBalanceAfter;

  const DriverTripPaymentModel({
    required this.totalPaid,
    required this.driverShare,
    required this.managerShare,
    required this.commissionRate,
    required this.walletBalanceAfter,
  });

  factory DriverTripPaymentModel.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return DriverTripPaymentModel(
      totalPaid: number('total_paid'),
      driverShare: number('driver_share'),
      managerShare: number('manager_share'),
      commissionRate: number('commission_rate'),
      walletBalanceAfter: number('wallet_balance_after'),
    );
  }

  @override
  List<Object?> get props => [
    totalPaid,
    driverShare,
    managerShare,
    commissionRate,
    walletBalanceAfter,
  ];
}
