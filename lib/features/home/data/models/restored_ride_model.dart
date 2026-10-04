import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';

/// A live ride found on the server after the app was closed: the ride plus
/// the two points the tracking screen needs, rebuilt from the ride's
/// `pickup_*` / `dropoff_*` fields (see swagger.json, schema `Ride`).
class RestoredRideModel extends Equatable {
  /// `requested`, `accepted`, `arrived`, `in_progress` — the ride is still
  /// being served. Anything else (completed, cancelled, scheduled) has no
  /// live screen to go back to.
  static const Set<int> _liveStatusIds = {1, 2, 3, 4};

  final RideModel ride;
  final PickedLocationModel pickup;
  final PickedLocationModel dropoff;

  const RestoredRideModel({
    required this.ride,
    required this.pickup,
    required this.dropoff,
  });

  factory RestoredRideModel.fromJson(Map<String, dynamic> json) {
    return RestoredRideModel(
      ride: RideModel.fromJson(json),
      pickup: PickedLocationModel(
        latitude: (json['pickup_lat'] as num).toDouble(),
        longitude: (json['pickup_lng'] as num).toDouble(),
        address: json['pickup_address'] as String?,
        addressDetails: json['pickup_address_details'] as String?,
      ),
      dropoff: PickedLocationModel(
        latitude: (json['dropoff_lat'] as num).toDouble(),
        longitude: (json['dropoff_lng'] as num).toDouble(),
        address: json['dropoff_address'] as String?,
        addressDetails: json['dropoff_address_details'] as String?,
      ),
    );
  }

  /// Whether a ride row with this [statusId] is one to put the customer
  /// back on.
  static bool isLiveStatus(int statusId) => _liveStatusIds.contains(statusId);

  @override
  List<Object?> get props => [ride, pickup, dropoff];
}
