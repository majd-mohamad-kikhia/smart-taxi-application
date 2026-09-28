import 'package:dio/dio.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/push_notification_service.dart';
import '../models/auth_user_model.dart';

/// Remote data source for the Auth feature. Talks to the Customer Auth
/// endpoints via [Dio] — see `swagger.json` for the full contract.
class AuthRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;
  final PushNotificationService _pushNotifications;

  const AuthRemoteDataSource(
    this._dio,
    this._endpoints,
    this._pushNotifications,
  );

  Future<AuthUserModel> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _dio.post(
      _endpoints.customerLogin,
      data: {
        'phone_number': phone,
        'password': password,
        ...await _pushNotifications.deviceTokenFields(),
      },
    );
    return AuthUserModel.fromApiData(
      response.data['data'] as Map<String, dynamic>,
      role: role,
    );
  }

  Future<AuthUserModel> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _dio.post(
      _endpoints.customerSignup,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phone,
        'password': password,
        ...await _pushNotifications.deviceTokenFields(),
      },
    );
    return AuthUserModel.fromApiData(
      response.data['data'] as Map<String, dynamic>,
      role: role,
    );
  }

  Future<void> logout({required String refreshToken}) {
    return _dio.post(
      _endpoints.customerLogout,
      data: {'refresh_token': refreshToken},
    );
  }
}
