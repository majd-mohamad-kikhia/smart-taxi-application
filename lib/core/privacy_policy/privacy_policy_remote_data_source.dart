import 'package:dio/dio.dart';
import '../models/privacy_policy_model.dart';
import '../network/api_endpoints.dart';

/// Reads the privacy policy — `GET /api/privacy-policy?lang=`.
/// Public: works without a token, so it can be shown on the sign-up screen.
class PrivacyPolicyRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  const PrivacyPolicyRemoteDataSource(this._dio, this._endpoints);

  Future<PrivacyPolicyModel> fetchPrivacyPolicy(String languageCode) async {
    final response = await _dio.get(
      _endpoints.privacyPolicy,
      queryParameters: {'lang': languageCode},
    );
    return PrivacyPolicyModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
