import 'package:equatable/equatable.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/models/route_point_model.dart';

/// Ride lifecycle status (`status_id` in swagger.json's `Ride` schema).
/// Listed with [scheduled] first so the filter reads "upcoming → done".
enum RideStatus {
  scheduled(7),
  requested(1),
  accepted(2),
  arrived(3),
  inProgress(4),
  completed(5),
  cancelled(6);

  final int id;

  const RideStatus(this.id);

  String label(AppLocalizations l10n) => switch (this) {
        RideStatus.scheduled => l10n.rideStatusScheduled,
        RideStatus.requested => l10n.rideStatusPending,
        RideStatus.accepted => l10n.rideStatusAcceptedHist,
        RideStatus.arrived => l10n.rideStatusArrivedHist,
        RideStatus.inProgress => l10n.rideStatusInProgressHist,
        RideStatus.completed => l10n.rideStatusCompletedHist,
        RideStatus.cancelled => l10n.rideStatusCancelledHist,
      };

  static RideStatus fromId(int id) => RideStatus.values.firstWhere(
        (s) => s.id == id,
        orElse: () => RideStatus.requested,
      );

  /// Waiting for, or on its way with, a driver — the tracking screen can
  /// follow it.
  bool get isLive => switch (this) {
        RideStatus.requested ||
        RideStatus.accepted ||
        RideStatus.arrived ||
        RideStatus.inProgress =>
          true,
        _ => false,
      };
}

/// An intermediate stop (`RideStop` schema).
class RideStopModel extends Equatable {
  final int order;
  final String? address;
  final double? feeCharged;

  const RideStopModel({required this.order, this.address, this.feeCharged});

  factory RideStopModel.fromJson(Map<String, dynamic> json) {
    return RideStopModel(
      order: json['stop_order'] as int? ?? 0,
      address: json['address'] as String?,
      feeCharged: (json['fee_charged'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [order, address, feeCharged];
}

/// A customer ride from `GET /api/customer/rides` and
/// `GET /api/customer/rides/{id}` (`Ride` schema). [stops] and [route] are
/// only filled by the detail endpoint; lists only carry [hasRoute].
class RideHistoryModel extends Equatable {
  final int id;
  final RideStatus status;

  /// The server's status key (`requested`, `accepted`, …).
  final String statusName;
  final int vehicleTypeId;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;
  final String? pickupAddressDetails;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffAddress;
  final String? dropoffAddressDetails;

  /// The customer's note for the driver.
  final String? note;

  /// People in the car, written by the office or the driver at the start.
  final int? passengersCount;

  /// Scheduled rides only (UTC): the pickup time, and when it was offered
  /// to drivers.
  final String? scheduledAt;
  final String? dispatchedAt;
  final double? distanceKm;
  final int? estimatedDurationMin;
  /// The estimate until the ride is completed; the final price after.
  final double price;
  final double? estimatedPrice;

  /// Amount due, set once the ride is completed.
  final double? finalPrice;
  final double stopsFeeTotal;
  final double waitingFee;
  final double pauseFeeTotal;

  /// Number and total length of the trip's pauses (detail only).
  final int pauseCount;
  final int pauseTotalSeconds;

  /// Distance the driver reported at finish; null until completed.
  final double? actualDistanceKm;

  /// The driver (or a manager) confirmed the customer paid.
  final bool isPaid;
  final String? paidAt;
  final String requestedAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final List<RideStopModel> stops;

  /// Whether the driver's driven route was uploaded for this ride.
  final bool hasRoute;

  /// The path the driver actually drove, in time order (detail only).
  final List<RoutePointModel> route;

  const RideHistoryModel({
    required this.id,
    required this.status,
    this.statusName = '',
    this.vehicleTypeId = 0,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.pickupAddressDetails,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffAddress,
    this.dropoffAddressDetails,
    this.note,
    this.passengersCount,
    this.scheduledAt,
    this.dispatchedAt,
    this.distanceKm,
    this.estimatedDurationMin,
    required this.price,
    this.estimatedPrice,
    this.finalPrice,
    required this.stopsFeeTotal,
    this.waitingFee = 0,
    this.pauseFeeTotal = 0,
    this.pauseCount = 0,
    this.pauseTotalSeconds = 0,
    this.actualDistanceKm,
    this.isPaid = false,
    this.paidAt,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.stops = const [],
    this.hasRoute = false,
    this.route = const [],
  });

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    final route = (json['route'] as List<dynamic>? ?? const [])
        .map((p) => RoutePointModel(
              ((p as Map<String, dynamic>)['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ))
        .toList();
    final pauses = json['pauses'] is List ? json['pauses'] as List : const [];
    return RideHistoryModel(
      id: json['id'] as int,
      status: RideStatus.fromId(json['status_id'] as int),
      statusName: json['status'] as String? ?? '',
      vehicleTypeId: (json['vehicle_type_id'] as num?)?.toInt() ?? 0,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      pickupAddress: json['pickup_address'] as String?,
      pickupAddressDetails: json['pickup_address_details'] as String?,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      dropoffAddress: json['dropoff_address'] as String?,
      dropoffAddressDetails: json['dropoff_address_details'] as String?,
      note: json['note'] as String?,
      passengersCount: (json['passengers_count'] as num?)?.toInt(),
      scheduledAt: json['scheduled_at'] as String?,
      dispatchedAt: json['dispatched_at'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: json['estimated_duration_min'] as int?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      stopsFeeTotal: (json['stops_fee_total'] as num?)?.toDouble() ?? 0,
      waitingFee: (json['waiting_fee'] as num?)?.toDouble() ?? 0,
      pauseFeeTotal: (json['pause_fee_total'] as num?)?.toDouble() ?? 0,
      pauseCount: pauses.length,
      pauseTotalSeconds: pauses.fold<int>(
        0,
        (sum, p) =>
            sum + (p is Map ? (p['duration_seconds'] as num?)?.toInt() ?? 0 : 0),
      ),
      actualDistanceKm: (json['actual_distance_km'] as num?)?.toDouble(),
      isPaid: json['payment_status'] == 'paid',
      paidAt: json['paid_at'] as String?,
      requestedAt: json['requested_at'] as String? ?? '',
      acceptedAt: json['accepted_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      stops: (json['stops'] as List<dynamic>? ?? const [])
          .map((s) => RideStopModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      hasRoute: json['has_route'] as bool? ?? route.isNotEmpty,
      route: route,
    );
  }

  bool get isCompleted => status == RideStatus.completed;

  bool get isScheduled => status == RideStatus.scheduled;

  bool get canTrack => status.isLive && pickupLat != null && dropoffLat != null;

  /// The ride as the tracking screen starts from.
  RideModel toRideModel() => RideModel(
        id: id,
        vehicleTypeId: vehicleTypeId,
        distanceKm: distanceKm,
        price: price,
        priceIsEstimate: isPriceEstimate,
        statusId: status.id,
        status: statusName,
        scheduledAt: scheduledAt,
      );

  PickedLocationModel get pickupLocation => PickedLocationModel(
        latitude: pickupLat ?? 0,
        longitude: pickupLng ?? 0,
        address: pickupAddress,
        addressDetails: pickupAddressDetails,
      );

  PickedLocationModel get dropoffLocation => PickedLocationModel(
        latitude: dropoffLat ?? 0,
        longitude: dropoffLng ?? 0,
        address: dropoffAddress,
        addressDetails: dropoffAddressDetails,
      );

  /// The price to show for this ride, or null when none should be shown: a
  /// cancelled ride shows no price, so it never reads as a charge.
  double? get shownPrice => switch (status) {
        RideStatus.cancelled => null,
        RideStatus.completed => finalPrice ?? price,
        _ => price,
      };

  /// Until the ride is completed the price is only the estimate.
  bool get isPriceEstimate => !isCompleted;

  /// The distance driven when known, otherwise the order-time estimate.
  double? get shownDistanceKm => actualDistanceKm ?? distanceKm;

  /// Base fare plus distance fare: what is left of the final price once the
  /// stop, waiting and pause fees are taken out (the API sends no separate
  /// base and distance amounts).
  double get tripFare =>
      (finalPrice ?? price) - stopsFeeTotal - waitingFee - pauseFeeTotal;

  @override
  List<Object?> get props => [
        id,
        status,
        statusName,
        vehicleTypeId,
        pickupLat,
        pickupLng,
        pickupAddress,
        pickupAddressDetails,
        dropoffLat,
        dropoffLng,
        dropoffAddress,
        dropoffAddressDetails,
        note,
        passengersCount,
        scheduledAt,
        dispatchedAt,
        distanceKm,
        estimatedDurationMin,
        price,
        estimatedPrice,
        finalPrice,
        stopsFeeTotal,
        waitingFee,
        pauseFeeTotal,
        pauseCount,
        pauseTotalSeconds,
        actualDistanceKm,
        isPaid,
        paidAt,
        requestedAt,
        acceptedAt,
        startedAt,
        completedAt,
        cancelledAt,
        cancellationReason,
        cancelledBy,
        stops,
        hasRoute,
        route,
      ];
}

/// One page of `GET /api/customer/rides` (`RideListData` schema).
class RideHistoryPage extends Equatable {
  final List<RideHistoryModel> rides;
  final int page;
  final int totalPages;

  const RideHistoryPage({
    required this.rides,
    required this.page,
    required this.totalPages,
  });

  factory RideHistoryPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    return RideHistoryPage(
      rides: (json['rides'] as List<dynamic>? ?? const [])
          .map((r) => RideHistoryModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? 1,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [rides, page, totalPages];
}
