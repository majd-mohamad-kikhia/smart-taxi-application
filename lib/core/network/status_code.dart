/// HTTP status codes referenced across the app's network layer — mirrors
/// the codes documented in `lib/features/auth/data/swagger.json`'s
/// `components.responses`.
class StatusCode {
  StatusCode._();

  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int validationError = 422;
  static const int internalError = 500;
}
