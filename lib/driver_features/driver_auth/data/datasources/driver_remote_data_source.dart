import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/driver_user_model.dart';

/// Remote data source for the Driver feature. Talks to the Driver Auth
/// endpoints via [Dio] — see `lib/features/auth/data/swagger.json` for
/// the full contract. Driver signup isn't implemented in this app (it
/// requires multipart photo uploads and is out of scope for now) —
/// drivers are onboarded another way and only log in here.
class DriverRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const DriverRemoteDataSource(this._dio, this._endpoints);

  Future<DriverUserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      _endpoints.driverLogin,
      data: {'phone_number': phone, 'password': password},
    );
    return DriverUserModel.fromApiData(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> logout({required String refreshToken}) {
    return _dio.post(
      _endpoints.driverLogout,
      data: {'refresh_token': refreshToken},
    );
  }

  /// Sets how far (in km) the driver accepts nearby ride requests. Returns
  /// the radius the server actually stored.
  Future<double> updateSearchRadius(double searchRadiusKm) async {
    final response = await _dio.put(
      _endpoints.driverSearchRadius,
      data: {'search_radius_km': searchRadiusKm},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['search_radius_km'] as num).toDouble();
  }
}
