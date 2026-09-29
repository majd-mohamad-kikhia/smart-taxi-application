import 'package:dio/dio.dart';
import '../enums/user_role.dart';
import '../localization/app_strings.dart';
import '../models/terms_model.dart';
import '../network/api_exception.dart';
import 'terms_remote_data_source.dart';

/// Structured failure thrown by [TermsRepository].
class TermsException implements Exception {
  final String message;

  const TermsException(this.message);

  @override
  String toString() => message;
}

class TermsRepository {
  final TermsRemoteDataSource _remote;

  const TermsRepository(this._remote);

  Future<TermsModel> getTerms(UserRole role, String languageCode) async {
    try {
      return await _remote.fetchTerms(role, languageCode);
    } on DioException catch (e) {
      final error = e.error;
      throw TermsException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
