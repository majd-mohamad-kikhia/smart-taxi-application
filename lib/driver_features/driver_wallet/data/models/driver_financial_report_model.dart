import 'package:equatable/equatable.dart';

/// A driver's monthly financial summary — mirrors the `data` object
/// returned by `GET /api/driver/financial-report` in swagger.json.
class DriverFinancialReportModel extends Equatable {
  final int year;
  final int month;
  final int ordersCount;
  final double ordersTotalAmount;
  final double driverEarnings;
  final double managerEarnings;
  final double? avgCommissionRate;
  final double rewardsTotal;
  final int rewardsCount;
  final double finesTotal;
  final int finesCount;
  final double compensationsTotal;
  final int compensationsCount;
  final double netIncome;
  final double walletBalance;

  const DriverFinancialReportModel({
    required this.year,
    required this.month,
    required this.ordersCount,
    required this.ordersTotalAmount,
    required this.driverEarnings,
    required this.managerEarnings,
    required this.avgCommissionRate,
    required this.rewardsTotal,
    required this.rewardsCount,
    required this.finesTotal,
    required this.finesCount,
    required this.compensationsTotal,
    required this.compensationsCount,
    required this.netIncome,
    required this.walletBalance,
  });

  factory DriverFinancialReportModel.fromJson(Map<String, dynamic> json) {
    return DriverFinancialReportModel(
      year: json['year'] as int,
      month: json['month'] as int,
      ordersCount: json['orders_count'] as int,
      ordersTotalAmount: (json['orders_total_amount'] as num).toDouble(),
      driverEarnings: (json['driver_earnings'] as num).toDouble(),
      managerEarnings: (json['manager_earnings'] as num).toDouble(),
      avgCommissionRate: (json['avg_commission_rate'] as num?)?.toDouble(),
      rewardsTotal: (json['rewards_total'] as num).toDouble(),
      rewardsCount: json['rewards_count'] as int,
      finesTotal: (json['fines_total'] as num).toDouble(),
      finesCount: json['fines_count'] as int,
      compensationsTotal: (json['compensations_total'] as num).toDouble(),
      compensationsCount: json['compensations_count'] as int,
      netIncome: (json['net_income'] as num).toDouble(),
      walletBalance: (json['wallet_balance'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    year,
    month,
    ordersCount,
    ordersTotalAmount,
    driverEarnings,
    managerEarnings,
    avgCommissionRate,
    rewardsTotal,
    rewardsCount,
    finesTotal,
    finesCount,
    compensationsTotal,
    compensationsCount,
    netIncome,
    walletBalance,
  ];
}
