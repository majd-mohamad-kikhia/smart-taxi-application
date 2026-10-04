import 'package:dio/dio.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/restored_ride_model.dart';
import '../models/ride_booking_options_model.dart';
import '../models/ride_quote_model.dart';

/// Remote data source for the customer order flow (see swagger.json,
/// tag "Customer Rides").
///
/// Flow: [resolveLocations] (step 1, creates nothing — returns a price
/// quote per vehicle type) → [chooseVehicle] (step 2, *creates* the ride
/// with `status_id = 1`) → [cancelRide].
///
/// `POST /api/customer/rides` is deliberately NOT used: swagger gives it
/// the same `CreateRideRequest` body and it also creates a ride with
/// `status_id = 1`, so calling it after [chooseVehicle] would create a
/// duplicate order.
class RideRequestRemoteDataSource {
  /// How many of the newest rides [fetchActiveRide] looks through.
  static const int _recentRidesLimit = 10;

  final Dio _dio;
  final ApiEndpoints _endpoints;

  const RideRequestRemoteDataSource(this._dio, this._endpoints);

  Future<RideQuoteModel> resolveLocations({
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    final response = await _dio.post(
      _endpoints.customerRideLocations,
      data: _locationsBody(pickup: pickup, dropoff: dropoff),
    );
    return RideQuoteModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// A [scheduledAt] (30 min – 7 days ahead) creates a `scheduled` ride
  /// (status 7) that the server offers to drivers 15 minutes before it.
  Future<RideModel> chooseVehicle({
    required RideBookingOptionsModel options,
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) async {
    final note = options.note?.trim();
    final response = await _dio.post(
      _endpoints.customerRideChooseVehicle,
      data: {
        'vehicle_type_id': options.vehicleTypeId,
        ..._locationsBody(pickup: pickup, dropoff: dropoff),
        if (note != null && note.isNotEmpty) 'note': note,
        'scheduled_at': ?options.scheduledAt?.toUtc().toIso8601String(),
      },
    );
    return RideModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// The customer's ride that is still being served, or null. There is no
  /// "active" endpoint for customers, so this reads the newest rides
  /// (`GET /api/customer/rides`, newest first) and picks the first live
  /// one — a customer has one live ride at a time, so it is always near the
  /// top.
  Future<RestoredRideModel?> fetchActiveRide() async {
    final response = await _dio.get(
      _endpoints.customerRides,
      queryParameters: {'page': 1, 'limit': _recentRidesLimit},
    );
    final rides = (response.data['data']['rides'] as List)
        .cast<Map<String, dynamic>>();
    for (final json in rides) {
      if (RestoredRideModel.isLiveStatus(json['status_id'] as int)) {
        return RestoredRideModel.fromJson(json);
      }
    }
    return null;
  }

  Future<RideModel> cancelRide({
    required int rideId,
    String? cancellationReason,
  }) async {
    final response = await _dio.post(
      _endpoints.customerRideCancel(rideId),
      data: {'cancellation_reason': ?cancellationReason},
    );
    return RideModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _locationsBody({
    required PickedLocationModel pickup,
    required PickedLocationModel dropoff,
  }) {
    return {
      'pickup_lat': pickup.latitude,
      'pickup_lng': pickup.longitude,
      'pickup_address': ?pickup.address,
      'pickup_address_details': ?pickup.addressDetails,
      'dropoff_lat': dropoff.latitude,
      'dropoff_lng': dropoff.longitude,
      'dropoff_address': ?dropoff.address,
      'dropoff_address_details': ?dropoff.addressDetails,
    };
  }
}
