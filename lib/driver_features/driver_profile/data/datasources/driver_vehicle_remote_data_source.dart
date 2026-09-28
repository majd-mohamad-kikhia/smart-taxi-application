import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../driver_auth/data/models/driver_vehicle_model.dart';

/// Remote data source for the driver profile's vehicle card — talks to
/// `GET /api/driver/vehicle` (see swagger.json).
class DriverVehicleRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverVehicleRemoteDataSource(this._dio, this._endpoints);

  Future<DriverVehicleModel> fetchVehicle() async {
    final response = await _dio.get(_endpoints.driverVehicle);
    return DriverVehicleModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
