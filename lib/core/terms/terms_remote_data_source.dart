import 'package:dio/dio.dart';
import '../enums/user_role.dart';
import '../models/terms_model.dart';
import '../network/api_endpoints.dart';

/// Reads the terms and conditions — `GET /api/terms/{audience}?lang=`.
/// Public: works without a token, so it can be shown on the sign-up screen.
class TermsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const TermsRemoteDataSource(this._dio, this._endpoints);

  Future<TermsModel> fetchTerms(UserRole role, String languageCode) async {
    final audience = switch (role) {
      UserRole.rider => 'customer',
      UserRole.driver => 'driver',
    };
    final response = await _dio.get(
      _endpoints.terms(audience),
      queryParameters: {'lang': languageCode},
    );
    return TermsModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
