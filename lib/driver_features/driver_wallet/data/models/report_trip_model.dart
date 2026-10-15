import 'package:equatable/equatable.dart';
import 'report_json.dart';

/// How a trip was ordered (`order_source`). Anything unknown reads as [app].
enum ReportOrderSource {
  app,
  call,
  whatsapp;

  static ReportOrderSource fromApi(Object? value) => switch (value) {
    'call' => ReportOrderSource.call,
    'whatsapp' => ReportOrderSource.whatsapp,
    _ => ReportOrderSource.app,
  };
}

/// The month's numbers for the "completed trips" card — `summary` of
/// `GET /api/driver/financial-report/trips`.
class TripsSummaryModel extends Equatable {
  final int ordersCount;
  final double totalDistanceKm;
  final double ordersTotalAmount;

  const TripsSummaryModel({
    required this.ordersCount,
    required this.totalDistanceKm,
    required this.ordersTotalAmount,
  });

  factory TripsSummaryModel.fromJson(Map<String, dynamic> json) {
    return TripsSummaryModel(
      ordersCount: json['orders_count'] as int? ?? 0,
      totalDistanceKm: reportNum(json['total_distance_km']),
      ordersTotalAmount: reportNum(json['orders_total_amount']),
    );
  }

  @override
  List<Object?> get props => [ordersCount, totalDistanceKm, ordersTotalAmount];
}

/// One completed trip of the month (`trips[]`). Times are UTC server text.
class ReportTripModel extends Equatable {
  final int id;
  final String? requestedAt;
  final String? startedAt;
  final String? completedAt;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double distanceKm;
  final int? durationMin;
  final String? vehicleTypeName;
  final String? customerFirstName;
  final ReportOrderSource orderSource;
  final double price;
  final bool isPaid;
  final String? paidAt;

  /// The customer's 1–5 rating of this trip; null when not rated.
  final int? rating;

  const ReportTripModel({
    required this.id,
    this.requestedAt,
    this.startedAt,
    this.completedAt,
    this.pickupAddress,
    this.dropoffAddress,
    required this.distanceKm,
    this.durationMin,
    this.vehicleTypeName,
    this.customerFirstName,
    required this.orderSource,
    required this.price,
    required this.isPaid,
    this.paidAt,
    this.rating,
  });

  factory ReportTripModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle_type'];
    return ReportTripModel(
      id: json['id'] as int,
      requestedAt: reportText(json['requested_at']),
      startedAt: reportText(json['started_at']),
      completedAt: reportText(json['completed_at']),
      pickupAddress: reportText(json['pickup_address']),
      dropoffAddress: reportText(json['dropoff_address']),
      distanceKm: reportNum(json['distance_km']),
      durationMin: (json['duration_min'] as num?)?.toInt(),
      vehicleTypeName: vehicle is Map ? reportText(vehicle['name']) : null,
      customerFirstName: reportText(json['customer_first_name']),
      orderSource: ReportOrderSource.fromApi(json['order_source']),
      price: reportNum(json['price']),
      isPaid: json['payment_status'] == 'paid',
      paidAt: reportText(json['paid_at']),
      rating: (json['rating'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    requestedAt,
    startedAt,
    completedAt,
    pickupAddress,
    dropoffAddress,
    distanceKm,
    durationMin,
    vehicleTypeName,
    customerFirstName,
    orderSource,
    price,
    isPaid,
    paidAt,
    rating,
  ];
}
