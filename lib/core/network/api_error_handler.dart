import 'package:dio/dio.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/app_strings.dart';
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
    final l10n = AppStrings.current;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(l10n.errTimeout);
      case DioExceptionType.connectionError:
        return ApiException(l10n.errNoInternet);
      case DioExceptionType.cancel:
        return ApiException(l10n.errRequestCancelled);
      case DioExceptionType.badResponse:
        return _fromResponse(error, l10n);
      default:
        return ApiException(l10n.errUnexpected);
    }
  }

  ApiException _fromResponse(DioException error, AppLocalizations l10n) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final rawFieldErrors = _rawFieldErrors(body);
    return ApiException(
      _messageFor(error, statusCode, body, rawFieldErrors, l10n),
      statusCode: statusCode,
      fieldErrors: _translate(rawFieldErrors, l10n),
      rawErrors: rawFieldErrors,
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
  ///    [_fieldNamesMessage]), name the field(s) at fault in the active
  ///    language —
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
    AppLocalizations l10n,
  ) {
    // "Please charge your wallet first": the server already wrote it in the
    // driver's language, so it is shown as it is — like an ordering block's
    // message — instead of being matched against a translation table.
    final walletMessage = _walletTooLowMessage(body, rawFieldErrors);
    if (walletMessage != null) return walletMessage;

    if (rawFieldErrors != null) {
      for (final reason in rawFieldErrors.values) {
        final mapped = ApiErrorMessages.byFieldReason[_normalize(reason)];
        if (mapped != null) return mapped(l10n);
      }
      if (rawFieldErrors.length == 1) {
        final guidance =
            ApiErrorMessages.fieldGuidance[rawFieldErrors.keys.single];
        if (guidance != null) return guidance(l10n);
      }
      if (rawFieldErrors.isNotEmpty &&
          rawFieldErrors.keys.every(ApiErrorMessages.fieldLabels.containsKey)) {
        return _fieldNamesMessage(rawFieldErrors.keys, l10n);
      }
    }
    final message = _bodyMessage(body);
    if (message != null) {
      final mapped = ApiErrorMessages.byMessage[_normalize(message)];
      if (mapped != null) return mapped(l10n);
    }
    return _fallbackMessage(statusCode, error.requestOptions.path, l10n);
  }

  /// The server's own text of a low-wallet refusal (`errors.wallet_balance`),
  /// or null when this isn't one or the text is blank.
  String? _walletTooLowMessage(dynamic body, Map<String, String>? rawFieldErrors) {
    final reason = rawFieldErrors?[ApiException.walletBalanceField];
    if (reason == null) return null;
    final message = _bodyMessage(body) ?? reason;
    return message.trim().isEmpty ? null : message;
  }

  /// "Check: `field labels`" — used when the API flagged specific
  /// *user-entered* fields (every key has a known [ApiErrorMessages
  /// .fieldLabels] entry) but didn't give a reason we have an exact
  /// translation for. A field the app never sends as form input (e.g.
  /// `status_id` on a driver-login rejection) is never named this way —
  /// it's not something the user can act on, and the status-code
  /// fallback already has bespoke handling for those cases.
  String _fieldNamesMessage(Iterable<String> fields, AppLocalizations l10n) {
    final labels = fields
        .map((field) => ApiErrorMessages.fieldLabels[field]!(l10n))
        .toSet()
        .join(l10n.listSeparator);
    return l10n.errCheckFields(labels);
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

  /// Translates every raw reason into the active language via exact
  /// match — the values are shown to the user, so none may ever be the
  /// raw English text.
  Map<String, String>? _translate(
    Map<String, String>? rawFieldErrors,
    AppLocalizations l10n,
  ) {
    if (rawFieldErrors == null) return null;
    return rawFieldErrors.map((field, reason) {
      final message =
          ApiErrorMessages.byFieldReason[_normalize(reason)] ??
          ApiErrorMessages.fieldGuidance[field] ??
          ApiErrorMessages.unknownField;
      return MapEntry(field, message(l10n));
    });
  }

  String? _bodyMessage(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _fallbackMessage(
    int? statusCode,
    String path,
    AppLocalizations l10n,
  ) {
    switch (statusCode) {
      case StatusCode.badRequest:
        return l10n.errInvalidRequest;
      case StatusCode.unauthorized:
        // Same status code, two different real meanings (see
        // swagger.json): wrong phone/password on login vs. a
        // missing/expired access token everywhere else.
        final isLogin =
            path == _endpoints.customerLogin || path == _endpoints.driverLogin;
        return isLogin ? l10n.errWrongCredentials : l10n.errSessionExpired;
      case StatusCode.forbidden:
        // Driver login 403 also covers the undocumented "rejected"
        // status (the spec only gives pending/suspended examples).
        return path == _endpoints.driverLogin
            ? l10n.errAccountInactive
            : l10n.errNotAllowed;
      case StatusCode.notFound:
        return l10n.errNotFound;
      case StatusCode.conflict:
        // 409 is also a ride-state conflict (accept/cancel), where
        // "account exists" would be nonsense — only signup gets that.
        final isSignup =
            path == _endpoints.customerSignup ||
            path == _endpoints.driverSignup;
        return isSignup ? l10n.errAccountExists : l10n.errActionUnavailable;
      case StatusCode.validationError:
        return l10n.errCheckInput;
      case StatusCode.internalError:
        return l10n.errServer;
      default:
        return l10n.errUnexpected;
    }
  }
}
