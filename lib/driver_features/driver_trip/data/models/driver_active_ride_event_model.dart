import 'driver_active_ride_model.dart';

/// A `driver:active_ride` socket event: the driver's current ride (swagger
/// `DriverRide`), either bare or wrapped in `ride`, plus the flags telling
/// why it was sent.
class DriverActiveRideEventModel {
  final DriverActiveRideModel ride;

  /// The raw ride fields, for merging the edited details into an open trip.
  final Map<String, dynamic> rideJson;

  /// The office edited the trip (points, details, note, price).
  final bool detailsUpdated;

  /// A manager assigned the trip to this driver.
  final bool assignedByManager;

  const DriverActiveRideEventModel({
    required this.ride,
    required this.rideJson,
    required this.detailsUpdated,
    required this.assignedByManager,
  });

  int get rideId => ride.order.rideId;

  /// Null when there is no ride, or one the trip screen doesn't handle.
  static DriverActiveRideEventModel? tryParse(Map<String, dynamic> json) {
    final wrapped = json['ride'];
    final rideJson = wrapped is Map ? Map<String, dynamic>.from(wrapped) : json;
    if (rideJson['id'] is! num) return null;
    final ride = DriverActiveRideModel.tryParse(rideJson);
    if (ride == null) return null;
    bool flag(String key) => json[key] == true || rideJson[key] == true;
    return DriverActiveRideEventModel(
      ride: ride,
      rideJson: rideJson,
      detailsUpdated: flag('details_updated'),
      assignedByManager: flag('assigned_by_manager'),
    );
  }
}
