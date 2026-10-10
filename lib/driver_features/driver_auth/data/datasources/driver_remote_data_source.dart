import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/push_notification_service.dart';
import '../models/driver_signup_request_model.dart';
import '../models/driver_user_model.dart';

/// Remote data source for the Driver feature. Talks to the Driver Auth
/// endpoints via [Dio] — see `lib/features/auth/data/swagger.json` for
/// the full contract. A driver can also create his own account
/// ([signup], multipart with two photos); it stays pending until a manager
/// approves it.
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

  /// `POST /api/driver/auth/signup` (multipart): the driver and his car are
  /// created together, pending approval. The reply carries tokens, but the
  /// account can't be used until approved, so nothing is read from it.
  Future<void> signup(DriverSignupRequestModel request) async {
    final form = FormData.fromMap(request.toFields())
      ..files.addAll([
        MapEntry('photo', await MultipartFile.fromFile(request.photoPath, filename: 'photo.jpg')),
        MapEntry(
          'vehicle_photo',
          await MultipartFile.fromFile(request.vehiclePhotoPath, filename: 'vehicle.jpg'),
        ),
      ]);
    await _dio.post(_endpoints.driverSignup, data: form);
  }

  /// The active car types for the signup form (no token needed).
  Future<List<SignupVehicleType>> getSignupVehicleTypes() async {
    final response = await _dio.get(_endpoints.driverSignupVehicleTypes);
    final list = (response.data['data'] as Map)['vehicle_types'] as List;
    return [
      for (final item in list)
        SignupVehicleType.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
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
