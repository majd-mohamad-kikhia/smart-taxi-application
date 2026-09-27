import 'package:dio/dio.dart';
import 'api_error_handler.dart';

/// Centralized Dio client for the whole app.
///
/// Every feature's remote data source should send requests through
/// [ApiClient.dio] instead of creating its own [Dio] instance, so the
/// base URL, timeouts and interceptors (logging, token injection, error
/// parsing) stay consistent everywhere.
class ApiClient {
  late final Dio dio;
  final ApiErrorHandler _errorHandler;

  ApiClient(this._errorHandler) {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.addAll([
      _tokenInterceptor,
      _errorInterceptor,
      if (_enableLogging)
        LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  static const String _baseUrl = 'https://smart-taxi.ma-core.net';
  static const bool _enableLogging = true;

  /// Auth token used by [_tokenInterceptor], set by [AuthRepository] right
  /// after a successful login/signup, or when a saved session is
  /// restored at app startup (see `AuthLocalDataSource`).
  static String? authToken;

  late final InterceptorsWrapper _tokenInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = authToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  );

  late final InterceptorsWrapper _errorInterceptor = InterceptorsWrapper(
    onError: (DioException error, handler) {
      handler.next(
        DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: _errorHandler.handle(error),
        ),
      );
    },
  );
}
