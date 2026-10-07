import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/push_notification_service.dart';
import '../models/driver_user_model.dart';

/// Remote data source for the Driver feature. Talks to the Driver Auth
/// endpoints via [Dio] — see `lib/features/auth/data/swagger.json` for
/// the full contract. Driver signup isn't implemented in this app (it
/// requires multipart photo uploads and is out of scope for now) —
/// drivers are onboarded another way and only log in here.
class DriverRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;
  final PushNotificationService _pushNotifications;

  const DriverRemoteDataSource(
    this._dio,
    this._endpoints,
    this._pushNotifications,
  );

  Future<DriverUserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      _endpoints.driverLogin,
      data: {
        'phone_number': phone,
        'password': password,
        ...await _pushNotifications.deviceTokenFields(),
      },
    );
    return DriverUserModel.fromApiData(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Cheapest authenticated driver call (`GET .../account/deletion-request`),
  /// used only to find out whether the saved token is still accepted — it
  /// answers 401 once the account is deleted or the token has expired.
  Future<void> checkSession() => _dio.get(_endpoints.driverAccountDeletionRequest);

  /// The driver's current wallet balance: the first line of
  /// `GET /api/driver/wallet`'s history, which carries it. The login data
  /// has it too, but only as of the login.
  Future<double> getWalletBalance() async {
    final response = await _dio.get(
      _endpoints.driverWallet,
      queryParameters: {'page': 1, 'limit': 1},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['wallet_balance'] as num).toDouble();
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
