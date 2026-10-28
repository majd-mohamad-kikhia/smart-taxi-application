import 'package:equatable/equatable.dart';

/// The `ride.payment` block returned by
/// `POST /api/driver/rides/{id}/confirm-payment`: how the cash paid by the
/// customer was split, what went into the customer's wallet, and the
/// driver's wallet after everything.
class DriverTripPaymentModel extends Equatable {
  /// The cash actually paid (`amount_due`).
  final double totalPaid;
  final double driverShare;
  final double managerShare;
  final double commissionRate;
  final double walletBalanceAfter;

  /// The part of the fare the customer's wallet covered; the driver
  /// collected that much less cash.
  final double walletUsed;

  /// The change the driver left in the customer's wallet; 0 when none.
  final double walletCreditAdded;

  const DriverTripPaymentModel({
    required this.totalPaid,
    required this.driverShare,
    required this.managerShare,
    required this.commissionRate,
    required this.walletBalanceAfter,
    this.walletUsed = 0,
    this.walletCreditAdded = 0,
  });

  factory DriverTripPaymentModel.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return DriverTripPaymentModel(
      totalPaid: number('total_paid'),
      driverShare: number('driver_share'),
      managerShare: number('manager_share'),
      commissionRate: number('commission_rate'),
      walletBalanceAfter: number('wallet_balance_after'),
      walletUsed: number('wallet_used'),
      walletCreditAdded: number('wallet_credit_added'),
    );
  }

  @override
  List<Object?> get props => [
    totalPaid,
    driverShare,
    managerShare,
    commissionRate,
    walletBalanceAfter,
    walletUsed,
    walletCreditAdded,
  ];
}
