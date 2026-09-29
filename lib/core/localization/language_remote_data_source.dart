import 'package:dio/dio.dart';
import '../enums/user_role.dart';
import '../network/api_endpoints.dart';

/// Tells the backend which language the signed-in account uses, so pushes
/// and in-app notifications arrive in it — `PUT /api/customer/profile/language`
/// for riders, `PUT /api/driver/language` for drivers (see swagger.json).
class LanguageRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const LanguageRemoteDataSource(this._dio, this._endpoints);

  Future<void> saveLanguage(UserRole role, String languageCode) async {
    final path = switch (role) {
      UserRole.rider => _endpoints.customerLanguage,
      UserRole.driver => _endpoints.driverLanguage,
    };
    await _dio.put(path, data: {'language': languageCode});
  }
}
