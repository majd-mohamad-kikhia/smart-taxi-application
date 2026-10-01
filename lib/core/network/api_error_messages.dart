import '../l10n/generated/app_localizations.dart';

/// A localized message, resolved against whichever language is active at
/// the moment an error is mapped.
typedef LocalizedMessage = String Function(AppLocalizations l10n);

/// Exact, full-string lookup tables for every error literal documented in
/// `lib/features/auth/data/swagger.json`.
///
/// Keys are the API's English text normalized with `trim().toLowerCase()`.
/// Matching is whole-string equality — never `contains` — so a sentence
/// that merely resembles a documented one (e.g. a future "password is too
/// weak") is never mistaken for it. An undocumented literal simply misses
/// the table and falls through to [ApiErrorHandler]'s status-code
/// fallback instead of being guessed at.
///
/// Values are [LocalizedMessage]s (not plain strings) so the same table
/// serves every supported language.
class ApiErrorMessages {
  ApiErrorMessages._();

  /// `ErrorResponse.message` literals — from swagger's
  /// `components/responses` (BadRequest, Unauthorized, Forbidden,
  /// Conflict, ValidationError, NotFound, InternalError) plus the two
  /// `POST /api/driver/auth/login` 403 examples (pending/suspended).
  static final Map<String, LocalizedMessage> byMessage = {
    'invalid json body': (l) => l.errInvalidRequest,
    'invalid phone number or password': (l) => l.errWrongCredentials,
    'customer access only': (l) => l.errAccountNotForApp,
    'account already exists': (l) => l.errAccountExists,
    'validation failed': (l) => l.errCheckInput,
    'route not found': (l) => l.errServiceUnavailable,
    'internal server error': (l) => l.errServer,
    'your account is pending approval': (l) => l.errAccountPending,
    'your account is suspended': (l) => l.errAccountSuspended,
    // 401 on any call once a driver's deletion request was approved.
    'this account has been deleted': (l) => l.errAccountDeleted,
  };

  /// `ErrorResponse.errors` reason literals — from the `ErrorResponse`
  /// schema example and the response examples across the spec. The
  /// reason text already embeds its field's meaning, so one flat table
  /// (keyed by reason, not by field+reason) covers every field.
  static final Map<String, LocalizedMessage> byFieldReason = {
    'first_name is required': (l) => l.errFieldRequired,
    'phone_number is required': (l) => l.errPhoneRequired,
    'phone_number is already registered': (l) => l.errPhoneRegistered,
    'password must be between 8 and 64 characters': (l) => l.errPasswordLength,
    'password must contain at least one number': (l) =>
        l.errPasswordNeedsNumber,
    'current status is pending; must be active': (l) => l.errAccountPending,
    'current status is suspended; must be active': (l) =>
        l.errAccountSuspended,
  };

  /// Shown for a field whose reason is not in [byFieldReason] — the
  /// field is known to have failed, but the sentence describing why is
  /// not documented, so nothing about it is inferred.
  static String unknownField(AppLocalizations l10n) => l10n.errCheckThisField;

  /// Label for every request field (body or query) the app itself
  /// ever sends, across every endpoint documented in swagger.json that
  /// this app calls (customer + driver — the spec's `/api/admin/*`
  /// endpoints have no UI in this app and are intentionally excluded).
  ///
  /// The API's exact validation-failure *wording* per field is mostly
  /// undocumented (only [byFieldReason]'s handful of literals are
  /// confirmed), so [ApiErrorHandler] never guesses that sentence — but
  /// the field *name* that failed is always given verbatim in the
  /// response's `errors` object, and is reliable. This table lets the
  /// handler name that field in the user's language instead of falling
  /// back to a fully generic "check your input" with no actionable detail.
  static final Map<String, LocalizedMessage> fieldLabels = {
    // Auth (customer + driver share the same field names)
    'first_name': (l) => l.fieldFirstName,
    'last_name': (l) => l.fieldLastName,
    'phone_number': (l) => l.phoneNumber,
    'password': (l) => l.password,
    'email': (l) => l.email,
    'address': (l) => l.address,
    'refresh_token': (l) => l.fieldSession,
    // Complaints (customer + driver)
    'message': (l) => l.fieldMessage,
    'subject': (l) => l.fieldSubject,
    // Customer rides
    'vehicle_type_id': (l) => l.fieldVehicleType,
    'pickup_lat': (l) => l.fieldPickupLocation,
    'pickup_lng': (l) => l.fieldPickupLocation,
    'pickup_address': (l) => l.fieldPickupAddress,
    'dropoff_lat': (l) => l.fieldDropoffLocation,
    'dropoff_lng': (l) => l.fieldDropoffLocation,
    'dropoff_address': (l) => l.fieldDropoffAddress,
    'cancellation_reason': (l) => l.fieldCancelReason,
    // Driver settings
    'search_radius_km': (l) => l.fieldSearchRadius,
  };

  /// Concrete, actionable requirement text for a field, built from
  /// swagger.json's **documented schema constraints**
  /// (`minLength`/`maxLength`/`minimum`/`maximum`/`description`) — not
  /// from a guessed reason sentence. Used instead of [fieldLabels]'s bare
  /// field name whenever the field failed for a reason that isn't one of
  /// [byFieldReason]'s exact literals, so the user is told what the
  /// field actually requires instead of just which field to "check".
  ///
  /// Example: password has three documented rules (`CustomerSignupRequest
  /// .password`'s description: "8–64 chars, no spaces, at least one
  /// letter and one number"), but swagger only gives an example reason
  /// for two of them (length, letter+number). A rejection for containing
  /// a space has no matching [byFieldReason] literal, so without this it
  /// would fall to a vague "check the password" — this spells out the
  /// full rule instead, which covers whichever part actually failed.
  static final Map<String, LocalizedMessage> fieldGuidance = {
    'password': (l) => l.guidePassword,
    'first_name': (l) => l.guideFirstName,
    'last_name': (l) => l.guideLastName,
    'message': (l) => l.guideMessage,
    'subject': (l) => l.guideSubject,
    'search_radius_km': (l) => l.guideSearchRadius,
    'cancellation_reason': (l) => l.guideCancelReason,
  };
}
