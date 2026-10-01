import 'package:dio/dio.dart';
import '../../../network/api_endpoints.dart';
import '../models/app_version_model.dart';

/// Asks the server whether this app version may continue —
/// `GET /api/app/version-check`. Public: no token needed (the token
/// interceptor may still add one, which is harmless).
class AppVersionRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const AppVersionRemoteDataSource(this._dio, this._endpoints);

  /// [version] is sent as Flutter reports it (`1.2.3+45`); `Dio` encodes the
  /// `+` as `%2B` itself.
  Future<AppVersionModel> check({
    required AppVersionApp app,
    required String platform,
    required String version,
    required String lang,
  }) async {
    final response = await _dio.get(
      _endpoints.appVersionCheck,
      queryParameters: {
        'app': app.wireValue,
        'platform': platform,
        'version': version,
        'lang': lang,
      },
      // The launch must not hang on a bad network.
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    return AppVersionModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
