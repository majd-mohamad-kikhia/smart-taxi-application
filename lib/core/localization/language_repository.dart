import 'package:dio/dio.dart';
import '../enums/user_role.dart';
import '../network/api_exception.dart';
import 'app_strings.dart';
import 'language_remote_data_source.dart';

/// Structured failure thrown by [LanguageRepository].
class LanguageException implements Exception {
  final String message;

  const LanguageException(this.message);

  @override
  String toString() => message;
}

class LanguageRepository {
  final LanguageRemoteDataSource _remote;

  const LanguageRepository(this._remote);

  Future<void> saveLanguage(UserRole role, String languageCode) async {
    try {
      await _remote.saveLanguage(role, languageCode);
    } on DioException catch (e) {
      final error = e.error;
      throw LanguageException(
        error is ApiException ? error.message : AppStrings.current.errServerUnreachable,
      );
    }
  }
}
