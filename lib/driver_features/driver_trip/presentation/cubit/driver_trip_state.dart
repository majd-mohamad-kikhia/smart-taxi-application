import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import '../../../../core/models/route_point_model.dart';
import '../../data/models/driver_trip_customer_model.dart';
import '../../data/models/driver_trip_fare_model.dart';
import '../../data/models/driver_trip_payment_model.dart';
import '../../data/models/ride_cancellation_model.dart';
import '../../data/models/ride_order_source.dart';

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

  /// The finish call did not get through (no connection); the app keeps
  /// sending it until it does, or the driver taps Finish again.
  final bool isFinishQueued;

  /// Who cancelled, when the server said so (null for a cancel this device
  /// made itself).
  final RideCancelledBy? cancelledBy;
  final String? errorMessage;

  /// The driver's own position, streamed once the ride is in progress.
  final double? carLat;
  final double? carLng;

  /// Planned road route, pickup to dropoff — fixed for the whole trip.
  final List<RoutePointModel> routePoints;

  /// The road from the driver to the pickup (Google Routes), shown before the
  /// trip starts; empty once it has.
  final List<RoutePointModel> pickupRoute;

  /// The path the car has actually driven since the ride started.
  final List<RoutePointModel> drivenPath;

  /// Waiting at pickup, as last reported by the server: running after
  /// "arrived", final (with the fee) once the trip has started. Null when
  /// the driver never tapped arrived.
  final RideWaitingModel? waiting;

  /// Pauses during the trip, as last reported by the server: the running
  /// pause while paused, the closed pauses' totals otherwise. Null until the
  /// first pause.
  final RidePauseModel? pause;

  /// The server's final fare — set once the ride is finished.
  final DriverTripFareModel? fare;

  /// From the finish reply: how the ride was ordered, the rider, and when
  /// the trip ended (UTC) — what the bill of an office order needs.
  final RideOrderSource orderSource;
  final DriverTripCustomerModel? customer;
  final DateTime? completedAt;

  /// Cash-payment confirmation after the ride is finished. [payment] is the
  /// server's money split, when it sent one.
  final bool isConfirmingPayment;
  final bool isPaid;
  final DriverTripPaymentModel? payment;

  /// How many times the office edited this trip while it was open; each
  /// increase tells the driver once.
  final int detailsUpdateCount;

  const DriverTripState({
    required this.order,
    required this.status,
    required this.isUpdating,
    required this.isCancelling,
    required this.isCancelled,
    this.isFinishQueued = false,
    this.cancelledBy,
    this.errorMessage,
    this.carLat,
    this.carLng,
    this.routePoints = const [],
    this.drivenPath = const [],
    this.pickupRoute = const [],
    this.waiting,
    this.pause,
    this.fare,
    this.orderSource = RideOrderSource.app,
    this.customer,
    this.completedAt,
    this.isConfirmingPayment = false,
    this.isPaid = false,
    this.payment,
    this.detailsUpdateCount = 0,
  });

  factory DriverTripState.initial(
    OrderOfferModel order, {
    DriverTripStatus status = DriverTripStatus.accepted,
    RideWaitingModel? waiting,
    RidePauseModel? pause,
  }) {
    return DriverTripState(
      order: order,
      status: status,
      waiting: waiting,
      pause: pause,
      isUpdating: false,
      isCancelling: false,
      isCancelled: false,
    );
  }

  /// Most people the driver can pick before starting. The car type's own
  /// maximum isn't sent to the driver app, so the server rejects a number
  /// above it with a 422.
  static const maxPickablePassengers = 8;

  bool get isBusy => isUpdating || isCancelling;

  /// A customer app order: the driver writes how many got in when starting.
  /// An office order already has the reception's number.
  bool get needsPassengersCount => order.passengersCount == null;

  /// The trip is in progress but stopped (e.g. for a coffee).
  bool get isPaused => status == DriverTripStatus.inProgress && (pause?.isPaused ?? false);

  /// An office order that is finished and paid: its customer often has no
  /// app, so the driver sends them the bill on WhatsApp.
  bool get canSendBill => isPaid && fare != null && orderSource.isOffice;

  DriverTripState copyWith({
    OrderOfferModel? order,
    DriverTripStatus? status,
    bool? isUpdating,
    bool? isCancelling,
    bool? isCancelled,
    bool? isFinishQueued,
    RideCancelledBy? cancelledBy,
    String? errorMessage,
    double? carLat,
    double? carLng,
    List<RoutePointModel>? routePoints,
    List<RoutePointModel>? drivenPath,
    List<RoutePointModel>? pickupRoute,
    RideWaitingModel? waiting,
    RidePauseModel? pause,
    DriverTripFareModel? fare,
    RideOrderSource? orderSource,
    DriverTripCustomerModel? customer,
    DateTime? completedAt,
    bool? isConfirmingPayment,
    bool? isPaid,
    DriverTripPaymentModel? payment,
    int? detailsUpdateCount,
    bool clearError = false,
  }) {
    return DriverTripState(
      order: order ?? this.order,
      status: status ?? this.status,
      isUpdating: isUpdating ?? this.isUpdating,
      isCancelling: isCancelling ?? this.isCancelling,
      isCancelled: isCancelled ?? this.isCancelled,
      isFinishQueued: isFinishQueued ?? this.isFinishQueued,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      carLat: carLat ?? this.carLat,
      carLng: carLng ?? this.carLng,
      routePoints: routePoints ?? this.routePoints,
      drivenPath: drivenPath ?? this.drivenPath,
      pickupRoute: pickupRoute ?? this.pickupRoute,
      waiting: waiting ?? this.waiting,
      pause: pause ?? this.pause,
      fare: fare ?? this.fare,
      orderSource: orderSource ?? this.orderSource,
      customer: customer ?? this.customer,
      completedAt: completedAt ?? this.completedAt,
      isConfirmingPayment: isConfirmingPayment ?? this.isConfirmingPayment,
      isPaid: isPaid ?? this.isPaid,
      payment: payment ?? this.payment,
      detailsUpdateCount: detailsUpdateCount ?? this.detailsUpdateCount,
    );
  }

  @override
  List<Object?> get props => [
    order,
    status,
    isUpdating,
    isCancelling,
    isCancelled,
    isFinishQueued,
    cancelledBy,
    errorMessage,
    carLat,
    carLng,
    routePoints,
    drivenPath,
    pickupRoute,
    waiting,
    pause,
    fare,
    orderSource,
    customer,
    completedAt,
    isConfirmingPayment,
    isPaid,
    payment,
    detailsUpdateCount,
  ];
}
