import 'package:dio/dio.dart';
import '../../../network/api_endpoints.dart';
import '../../../network/status_code.dart';
import '../models/contact_number_model.dart';

/// Reads the "Contact us" numbers — `GET /api/contact-numbers?app=&lang=`.
/// Public: no token needed (the token interceptor may still add one, which
/// is harmless).
///
/// Keeps the last list and its `ETag` in memory, so opening the screen again
/// costs a `304` with no body when nothing changed. Register one instance
/// per [app] as a singleton so the cache survives between visits.
class ContactUsRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;
  final ContactUsApp app;

  String? _etag;
  String? _lang;
  List<ContactNumberModel>? _cached;

  ContactUsRemoteDataSource(this._dio, this._endpoints, {required this.app});

  /// On a `304` the very same list instance is returned, so callers can tell
  /// "nothing changed" with `identical`.
  Future<List<ContactNumberModel>> getContactNumbers({
    required String lang,
  }) async {
    final cached = _cached;
    final etag = _etag;
    final canRevalidate = cached != null && etag != null && _lang == lang;

    final response = await _dio.get(
      _endpoints.contactNumbers,
      queryParameters: {'app': app.wireValue, 'lang': lang},
      options: Options(
        headers: {if (canRevalidate) 'If-None-Match': etag},
        validateStatus: (s) =>
            s != null &&
            ((s >= 200 && s < 300) || s == StatusCode.notModified),
      ),
    );
    if (response.statusCode == StatusCode.notModified && canRevalidate) {
      return cached;
    }

    final list = (response.data['data'] as List)
        .map(
          (e) => ContactNumberModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
    _etag = response.headers.value('etag');
    _lang = lang;
    _cached = list;
    return list;
  }
}
