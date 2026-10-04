import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/ride_pause_model.dart';
import '../../../../core/models/ride_waiting_model.dart';
import 'recorded_route_point_model.dart';

/// The driver's current ride as returned by `GET /api/driver/rides/active`
/// (swagger `DriverRide`), used to put the driver back on the trip screen
/// after the app was killed.
///
/// `accepted` and `arrived` rides resume as they are. An `in_progress` ride
/// also needs the route saved on the device ([resumedRoute]) — the driven
/// distance the server prices from is measured on the phone, so without the
/// saved points the trip could not be finished with the right distance.
class DriverActiveRideModel extends Equatable {
  final OrderOfferModel order;
  final bool isArrived;
  final bool isInProgress;

  /// Waiting at pickup; while running, `elapsedSeconds` is the server's
  /// measurement at response time.
  final RideWaitingModel? waiting;

  /// Pauses so far; if paused, `current.elapsedSeconds` is the server's
  /// measurement at response time.
  final RidePauseModel? pause;

  /// Points recorded before the app was killed — set only for an
  /// in-progress ride.
  final List<RecordedRoutePointModel> resumedRoute;

  const DriverActiveRideModel({
    required this.order,
    required this.isArrived,
    this.isInProgress = false,
    this.waiting,
    this.pause,
    this.resumedRoute = const [],
  });

  /// Returns null for a status the trip screen doesn't resume.
  static DriverActiveRideModel? tryParse(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    if (status != 'accepted' &&
        status != 'arrived' &&
        status != 'in_progress') {
      return null;
    }
    return DriverActiveRideModel(
      order: OrderOfferModel(
        rideId: (json['id'] as num).toInt(),
        vehicleTypeId: (json['vehicle_type_id'] as num?)?.toInt() ?? 0,
        pickupLat: (json['pickup_lat'] as num).toDouble(),
        pickupLng: (json['pickup_lng'] as num).toDouble(),
        pickupAddress: json['pickup_address'] as String? ?? '',
        dropoffLat: (json['dropoff_lat'] as num).toDouble(),
        dropoffLng: (json['dropoff_lng'] as num).toDouble(),
        dropoffAddress: json['dropoff_address'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        estimatedDurationMin:
            (json['estimated_duration_min'] as num?)?.toInt() ?? 0,
        estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
        priceIsEstimate: true,
        requestedAt:
            DateTime.tryParse(json['requested_at'] as String? ?? '') ??
            DateTime.now(),
        distanceToPickupKm: 0,
        pickupAddressDetails: OrderOfferModel.textOrNull(
          json['pickup_address_details'],
        ),
        dropoffAddressDetails: OrderOfferModel.textOrNull(
          json['dropoff_address_details'],
        ),
        note: OrderOfferModel.textOrNull(json['note']),
        passengersCount: OrderOfferModel.countOrNull(json['passengers_count']),
        passengersFee: OrderOfferModel.feeOf(json),
      ),
      isArrived: status == 'arrived',
      isInProgress: status == 'in_progress',
      waiting: RideWaitingModel.fromParent(json),
      pause: RidePauseModel.fromParent(json),
    );
  }

  DriverActiveRideModel withRoute(List<RecordedRoutePointModel> route) {
    return DriverActiveRideModel(
      order: order,
      isArrived: isArrived,
      isInProgress: isInProgress,
      waiting: waiting,
      pause: pause,
      resumedRoute: route,
    );
  }

  @override
  List<Object?> get props => [
    order,
    isArrived,
    isInProgress,
    waiting,
    pause,
    resumedRoute.length,
  ];
}
