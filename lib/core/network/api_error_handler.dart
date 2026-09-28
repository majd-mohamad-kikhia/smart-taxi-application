import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_error_messages.dart';
import 'api_exception.dart';
import 'status_code.dart';

/// Centralized translator from a raw [DioException] to the app's
/// structured [ApiException].
///
/// The Smart Taxi API always answers in English (see the `ErrorResponse`
/// envelope and examples in `lib/features/auth/data/swagger.json`):
/// ```json
/// { "success": false, "message": "...", "errors": { "field": "reason" } }
/// ```
/// This handler never surfaces that raw English text — a *reason*
/// sentence (e.g. `"password must be ..."`) is only ever shown once
/// translated via an **exact, full-string match** against
/// [ApiErrorMessages.byFieldReason]/`byMessage`, built directly from
/// swagger.json's documented literals. Nothing is inferred from a
/// substring (no `contains('already')`/`contains('required')` guessing):
/// an undocumented reason sentence never gets shown verbatim or guessed
/// at. A field *name*, however (the `errors{}` object's keys), is always
/// given verbatim by the API and is reliable, so an undocumented reason
/// still surfaces as "which field(s) to check" via
/// [ApiErrorMessages.fieldLabels] before falling through to the fully
/// generic status-code fallback.
///
/// Registered in the service locator (see injection.dart) so [ApiClient]
/// and every repository share one instance instead of each rolling its
/// own error-mapping logic.
class ApiErrorHandler {
  final ApiEndpoints _endpoints;

  const ApiErrorHandler(this._endpoints);

  ApiException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('انتهت مهلة الاتصال بالخادم');
      case DioExceptionType.connectionError:
        return const ApiException('تعذر الاتصال بالإنترنت، تحقق من اتصالك');
      case DioExceptionType.cancel:
        return const ApiException('تم إلغاء الطلب');
      case DioExceptionType.badResponse:
        return _fromResponse(error);
      default:
        return const ApiException('حدث خطأ غير متوقع');
    }
  }

  ApiException _fromResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final rawFieldErrors = _rawFieldErrors(body);
    return ApiException(
      _messageFor(error, statusCode, body, rawFieldErrors),
      statusCode: statusCode,
      fieldErrors: _translate(rawFieldErrors),
    );
  }

  /// Resolution order:
  /// 1. the first `errors{}` reason that is a documented literal (exact
  ///    match — the API's precise wording, so the most trustworthy)
  /// 2. if exactly one field failed and none matched step 1, but the
  ///    field has documented schema constraints (see
  ///    [ApiErrorMessages.fieldGuidance]), spell out the actual
  ///    requirement (e.g. password's length/spaces/composition rule)
  ///    instead of just naming the field — this is what the user needs
  ///    to fix it, not just what to "check"
  /// 3. if there are field errors but none matched steps 1–2, and every
  ///    flagged field is a known user-facing field (see
  ///    [_fieldNamesMessage]), name the field(s) at fault in Arabic —
  ///    still beats a fully generic message with zero detail. Skipped
  ///    for an internal-only field (e.g. `status_id`), which falls
  ///    through instead since the user can't act on it by name
  /// 4. the top-level `message` if it is a documented literal
  /// 5. a deterministic fallback by status code + endpoint
  ///
  /// Field errors are checked first (steps 1–3) so a 422/409/403 shows
  /// the specific reason rather than the generic top-level message —
  /// steps 2–3 run *before* step 4 because swagger's generic
  /// `"Validation failed"` is itself a documented literal that maps to a
  /// fully generic string; without this ordering it would always win
  /// and steps 2–3 would never run.
  String _messageFor(
    DioException error,
    int? statusCode,
    dynamic body,
    Map<String, String>? rawFieldErrors,
  ) {
    if (rawFieldErrors != null) {
      for (final reason in rawFieldErrors.values) {
        final mapped = ApiErrorMessages.byFieldReason[_normalize(reason)];
        if (mapped != null) return mapped;
      }
      if (rawFieldErrors.length == 1) {
        final guidance =
            ApiErrorMessages.fieldGuidance[rawFieldErrors.keys.single];
        if (guidance != null) return guidance;
      }
      if (rawFieldErrors.isNotEmpty &&
          rawFieldErrors.keys.every(ApiErrorMessages.fieldLabels.containsKey)) {
        return _fieldNamesMessage(rawFieldErrors.keys);
      }
    }
    final message = _bodyMessage(body);
    if (message != null) {
      final mapped = ApiErrorMessages.byMessage[_normalize(message)];
      if (mapped != null) return mapped;
    }
    return _fallbackMessage(statusCode, error.requestOptions.path);
  }

  /// "تحقق من: `field labels`" — used when the API flagged specific
  /// *user-entered* fields (every key has a known [ApiErrorMessages
  /// .fieldLabels] entry) but didn't give a reason we have an exact
  /// translation for. A field the app never sends as form input (e.g.
  /// `status_id` on a driver-login rejection) is never named this way —
  /// it's not something the user can act on, and the status-code
  /// fallback already has bespoke handling for those cases.
  String _fieldNamesMessage(Iterable<String> fields) {
    final labels = fields
        .map((field) => ApiErrorMessages.fieldLabels[field]!)
        .toSet()
        .join('، ');
    return 'تحقق من: $labels';
  }

  /// Parses swagger's `errors: { field: reason }` map, keeping only
  /// `String` reasons — a malformed/unexpected body (a list, numbers,
  /// nested objects) yields `null` for that field rather than a garbled
  /// `toString()`.
  Map<String, String>? _rawFieldErrors(dynamic body) {
    if (body is! Map || body['errors'] is! Map) return null;
    final errors = <String, String>{};
    (body['errors'] as Map).forEach((field, reason) {
      if (reason is String) {
        errors[field.toString()] = reason;
      }
    });
    return errors.isEmpty ? null : errors;
  }

  /// Translates every raw reason to Arabic via exact match — the values
  /// are shown to the user, so none may ever be the raw English text.
  Map<String, String>? _translate(Map<String, String>? rawFieldErrors) {
    if (rawFieldErrors == null) return null;
    return rawFieldErrors.map(
      (field, reason) => MapEntry(
        field,
        ApiErrorMessages.byFieldReason[_normalize(reason)] ??
            ApiErrorMessages.fieldGuidance[field] ??
            ApiErrorMessages.unknownField,
      ),
    );
  }

  String? _bodyMessage(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _fallbackMessage(int? statusCode, String path) {
    switch (statusCode) {
      case StatusCode.badRequest:
        return 'طلب غير صالح';
      case StatusCode.unauthorized:
        // Same status code, two different real meanings (see
        // swagger.json): wrong phone/password on login vs. a
        // missing/expired access token everywhere else.
        final isLogin =
            path == _endpoints.customerLogin || path == _endpoints.driverLogin;
        return isLogin
            ? 'رقم الجوال أو كلمة المرور غير صحيحة'
            : 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً';
      case StatusCode.forbidden:
        // Driver login 403 also covers the undocumented "rejected"
        // status (the spec only gives pending/suspended examples).
        return path == _endpoints.driverLogin
            ? 'لا يمكن تسجيل الدخول، حسابك غير نشط حالياً'
            : 'غير مصرح لك بهذا الإجراء';
      case StatusCode.notFound:
        return 'العنصر المطلوب غير موجود';
      case StatusCode.conflict:
        // 409 is also a ride-state conflict (accept/cancel), where
        // "account exists" would be nonsense — only signup gets that.
        final isSignup =
            path == _endpoints.customerSignup ||
            path == _endpoints.driverSignup;
        return isSignup
            ? 'الحساب موجود بالفعل'
            : 'لا يمكن تنفيذ هذا الإجراء في الوقت الحالي';
      case StatusCode.validationError:
        return 'تحقق من البيانات المدخلة';
      case StatusCode.internalError:
        return 'حدث خطأ في الخادم، حاول لاحقاً';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
