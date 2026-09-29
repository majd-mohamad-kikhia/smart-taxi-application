import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../data/models/driver_trip_fare_model.dart';
import '../../data/models/driver_trip_payment_model.dart';

/// Where the driver is in the ride after accepting it:
/// accepted (2) → arrived (3, optional) → inProgress (4) → completed (5).
enum DriverTripStatus { accepted, arrived, inProgress, completed }

class DriverTripState extends Equatable {
  final OrderOfferModel order;
  final DriverTripStatus status;

  /// True while any status action (arrived / start / finish) is in flight.
  final bool isUpdating;

  final bool isCancelling;
  final bool isCancelled;
  final String? errorMessage;

  /// The driver's own position, streamed once the ride is in progress.
  final double? carLat;
  final double? carLng;

  /// Planned road route, pickup to dropoff — fixed for the whole trip.
  final List<RoutePointModel> routePoints;

  /// The path the car has actually driven since the ride started.
  final List<RoutePointModel> drivenPath;

  /// The server's final fare — set once the ride is finished.
  final DriverTripFareModel? fare;

  /// Cash-payment confirmation after the ride is finished. [payment] is the
  /// server's money split, when it sent one.
  final bool isConfirmingPayment;
  final bool isPaid;
  final DriverTripPaymentModel? payment;

  const DriverTripState({
    required this.order,
    required this.status,
    required this.isUpdating,
    required this.isCancelling,
    required this.isCancelled,
    this.errorMessage,
    this.carLat,
    this.carLng,
    this.routePoints = const [],
    this.drivenPath = const [],
    this.fare,
    this.isConfirmingPayment = false,
    this.isPaid = false,
    this.payment,
  });

  factory DriverTripState.initial(OrderOfferModel order) {
    return DriverTripState(
      order: order,
      status: DriverTripStatus.accepted,
      isUpdating: false,
      isCancelling: false,
      isCancelled: false,
    );
  }

  bool get isBusy => isUpdating || isCancelling;

  DriverTripState copyWith({
    DriverTripStatus? status,
    bool? isUpdating,
    bool? isCancelling,
    bool? isCancelled,
    String? errorMessage,
    double? carLat,
    double? carLng,
    List<RoutePointModel>? routePoints,
    List<RoutePointModel>? drivenPath,
    DriverTripFareModel? fare,
    bool? isConfirmingPayment,
    bool? isPaid,
    DriverTripPaymentModel? payment,
    bool clearError = false,
  }) {
    return DriverTripState(
      order: order,
      status: status ?? this.status,
      isUpdating: isUpdating ?? this.isUpdating,
      isCancelling: isCancelling ?? this.isCancelling,
      isCancelled: isCancelled ?? this.isCancelled,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      carLat: carLat ?? this.carLat,
      carLng: carLng ?? this.carLng,
      routePoints: routePoints ?? this.routePoints,
      drivenPath: drivenPath ?? this.drivenPath,
      fare: fare ?? this.fare,
      isConfirmingPayment: isConfirmingPayment ?? this.isConfirmingPayment,
      isPaid: isPaid ?? this.isPaid,
      payment: payment ?? this.payment,
    );
  }

  @override
  List<Object?> get props => [
    order,
    status,
    isUpdating,
    isCancelling,
    isCancelled,
    errorMessage,
    carLat,
    carLng,
    routePoints,
    drivenPath,
    fare,
    isConfirmingPayment,
    isPaid,
    payment,
  ];
}
