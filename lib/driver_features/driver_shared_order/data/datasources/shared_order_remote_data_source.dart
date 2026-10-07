import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../driver_trip/data/models/driver_active_ride_model.dart';
import '../models/shared_order_preview_model.dart';

/// Office orders opened from their WhatsApp link (swagger tag "Driver
/// Rides", `/api/driver/rides/shared/{token}`).
class SharedOrderRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const SharedOrderRemoteDataSource(this._dio, this._endpoints);

  /// The order and whether this driver may accept it. Also subscribes the
  /// driver's connected socket to the order's closed / updated events.
  Future<SharedOrderPreviewModel> preview(String token) async {
    final response = await _dio.get(_endpoints.driverSharedRide(token));
    final data = (response.data as Map)['data'] as Map;
    return SharedOrderPreviewModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// First driver wins. Returns the accepted ride, same as
  /// `POST /api/driver/rides/{id}/accept`; asking again for an order this
  /// driver already has returns the same ride. Null for a ride status the
  /// trip screen can't open. With [lat] and [lng] (the driver's position)
  /// the ride also carries `eta`, the time to the pickup.
  Future<DriverActiveRideModel?> accept(String token, {double? lat, double? lng}) async {
    final response = await _dio.post(
      _endpoints.driverSharedRideAccept(token),
      data: lat == null || lng == null ? null : {'lat': lat, 'lng': lng},
    );
    final data = (response.data as Map)['data'];
    return data is Map
        ? DriverActiveRideModel.tryParse(Map<String, dynamic>.from(data))
        : null;
  }
}
