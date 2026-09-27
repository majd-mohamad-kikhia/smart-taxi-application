/// Structured failure model for every network error.
///
/// Repositories only ever deal with [ApiException] (never a raw
/// `DioException`) — built by `ApiErrorHandler`, which is what "network
/// errors must be handled centrally" + "failures must return structured
/// error models" means in this project.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Per-field validation messages, e.g. `{"phone_number": "..."}`, as
  /// documented in swagger.json's `ErrorResponse.errors`. Only present
  /// for validation (422) and conflict (409) responses.
  final Map<String, String>? fieldErrors;

  const ApiException(this.message, {this.statusCode, this.fieldErrors});

  @override
  String toString() => message;
}
