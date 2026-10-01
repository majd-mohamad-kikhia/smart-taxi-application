import 'package:dio/dio.dart';
import '../localization/app_strings.dart';
import '../models/privacy_policy_model.dart';
import '../network/api_exception.dart';
import 'privacy_policy_remote_data_source.dart';

class PrivacyPolicyException implements Exception {
  final String message;

  const PrivacyPolicyException(this.message);

  @override
  String toString() => message;
}

class PrivacyPolicyRepository {
  final PrivacyPolicyRemoteDataSource _remote;

  const PrivacyPolicyRepository(this._remote);

  Future<PrivacyPolicyModel> getPrivacyPolicy(String languageCode) async {
    try {
      return await _remote.fetchPrivacyPolicy(languageCode);
    } on DioException catch (e) {
      final error = e.error;
      throw PrivacyPolicyException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
