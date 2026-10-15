import 'package:equatable/equatable.dart';
import 'report_json.dart';

/// The month's numbers for the "trip earnings" card — `summary` of
/// `GET /api/driver/financial-report/earnings`.
class EarningsSummaryModel extends Equatable {
  final int ordersCount;
  final double ordersTotalAmount;
  final double driverEarnings;
  final double managerEarnings;

  /// Average commission in percent; null when there are no trips.
  final double? avgCommissionRate;

  const EarningsSummaryModel({
    required this.ordersCount,
    required this.ordersTotalAmount,
    required this.driverEarnings,
    required this.managerEarnings,
    this.avgCommissionRate,
  });

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryModel(
      ordersCount: json['orders_count'] as int? ?? 0,
      ordersTotalAmount: reportNum(json['orders_total_amount']),
      driverEarnings: reportNum(json['driver_earnings']),
      managerEarnings: reportNum(json['manager_earnings']),
      avgCommissionRate: (json['avg_commission_rate'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    ordersCount,
    ordersTotalAmount,
    driverEarnings,
    managerEarnings,
    avgCommissionRate,
  ];
}

/// What a trip's price is made of (`fees`); the parts add up to the price.
class ReportFeesModel extends Equatable {
  final double distanceFare;
  final double stopsFee;
  final double locationFee;
  final double passengersFee;
  final double nightFee;
  final double timeFee;
  final double waitingFee;
  final double pauseFee;

  const ReportFeesModel({
    this.distanceFare = 0,
    this.stopsFee = 0,
    this.locationFee = 0,
    this.passengersFee = 0,
    this.nightFee = 0,
    this.timeFee = 0,
    this.waitingFee = 0,
    this.pauseFee = 0,
  });

  factory ReportFeesModel.fromJson(Map<String, dynamic> json) {
    return ReportFeesModel(
      distanceFare: reportNum(json['distance_fare']),
      stopsFee: reportNum(json['stops_fee']),
      locationFee: reportNum(json['location_fee']),
      passengersFee: reportNum(json['passengers_fee']),
      nightFee: reportNum(json['night_fee']),
      timeFee: reportNum(json['time_fee']),
      waitingFee: reportNum(json['waiting_fee']),
      pauseFee: reportNum(json['pause_fee']),
    );
  }

  @override
  List<Object?> get props => [
    distanceFare,
    stopsFee,
    locationFee,
    passengersFee,
    nightFee,
    timeFee,
    waitingFee,
    pauseFee,
  ];
}

/// The money split of one trip (`earnings[]`): what the customer paid, the
/// platform's commission, and what the driver kept.
class ReportEarningModel extends Equatable {
  final int id;
  final String? completedAt;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double price;

  /// The price was typed by the office, not calculated.
  final bool priceIsFixed;
  final double commissionRate;
  final double commissionAmount;
  final double driverEarning;
  final ReportFeesModel fees;
  final bool isPaid;

  const ReportEarningModel({
    required this.id,
    this.completedAt,
    this.pickupAddress,
    this.dropoffAddress,
    required this.price,
    required this.priceIsFixed,
    required this.commissionRate,
    required this.commissionAmount,
    required this.driverEarning,
    required this.fees,
    required this.isPaid,
  });

  factory ReportEarningModel.fromJson(Map<String, dynamic> json) {
    final fees = json['fees'];
    return ReportEarningModel(
      id: json['id'] as int,
      completedAt: reportText(json['completed_at']),
      pickupAddress: reportText(json['pickup_address']),
      dropoffAddress: reportText(json['dropoff_address']),
      price: reportNum(json['price']),
      priceIsFixed: json['price_is_fixed'] == true,
      commissionRate: reportNum(json['commission_rate']),
      commissionAmount: reportNum(json['commission_amount']),
      driverEarning: reportNum(json['driver_earning']),
      fees: fees is Map<String, dynamic>
          ? ReportFeesModel.fromJson(fees)
          : const ReportFeesModel(),
      isPaid: json['payment_status'] == 'paid',
    );
  }

  @override
  List<Object?> get props => [
    id,
    completedAt,
    pickupAddress,
    dropoffAddress,
    price,
    priceIsFixed,
    commissionRate,
    commissionAmount,
    driverEarning,
    fees,
    isPaid,
  ];
}
