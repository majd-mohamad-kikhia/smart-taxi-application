import 'package:equatable/equatable.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/models/ride_waiting_model.dart';

/// The reply to `POST /api/driver/rides/{id}/start` (swagger `DriverRide`).
class DriverRideStartModel extends Equatable {
  /// The stopped waiting timer with its final fee, or null when the driver
  /// never tapped arrived.
  final RideWaitingModel? waiting;

  /// The number saved on the ride: the driver's, or the office's for an
  /// office order (the driver's is ignored then).
  final int? passengersCount;

  const DriverRideStartModel({this.waiting, this.passengersCount});

  factory DriverRideStartModel.fromRideJson(Map<String, dynamic> json) {
    return DriverRideStartModel(
      waiting: RideWaitingModel.fromParent(json),
      passengersCount: OrderOfferModel.countOrNull(json['passengers_count']),
    );
  }

  @override
  List<Object?> get props => [waiting, passengersCount];
}
