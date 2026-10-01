import 'package:dio/dio.dart';
import '../../../localization/app_strings.dart';
import '../../../network/api_exception.dart';
import '../datasources/contact_us_remote_datasource.dart';
import '../models/contact_number_model.dart';

class ContactUsRepository {
  final ContactUsRemoteDataSource _remote;

  const ContactUsRepository(this._remote);

  /// Throws [ApiException] when the server can't be reached or rejects the
  /// request.
  Future<List<ContactNumberModel>> getContactNumbers({
    required String lang,
  }) async {
    try {
      return await _remote.getContactNumbers(lang: lang);
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }
}
