import 'package:dio/dio.dart';
import '../../../../core/models/planned_route_model.dart';
import '../../../../core/network/api_endpoints.dart';

/// Reads a ride's fixed road (`planned_route`) from
/// `GET /api/customer/rides/{id}`: for the one case where the order was made
/// before the server had worked the road out.
class RidePlannedRouteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const RidePlannedRouteDataSource(this._dio, this._endpoints);

  /// Null when the ride still has no road.
  Future<PlannedRouteModel?> fetch(int rideId) async {
    final response = await _dio.get(_endpoints.customerRideById(rideId));
    final data = response.data;
    final ride = data is Map ? data['data'] : null;
    return ride is Map ? PlannedRouteModel.tryParse(ride['planned_route']) : null;
  }
}
