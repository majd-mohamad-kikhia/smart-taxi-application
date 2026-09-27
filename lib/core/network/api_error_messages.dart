/// Exact, full-string lookup tables for every error literal documented in
/// `lib/features/auth/data/swagger.json`.
///
/// Keys are the API's English text normalized with `trim().toLowerCase()`.
/// Matching is whole-string equality — never `contains` — so a sentence
/// that merely resembles a documented one (e.g. a future "password is too
/// weak") is never mistaken for it. An undocumented literal simply misses
/// the table and falls through to [ApiErrorHandler]'s status-code
/// fallback instead of being guessed at.
class ApiErrorMessages {
  ApiErrorMessages._();

  /// `ErrorResponse.message` literals — from swagger's
  /// `components/responses` (BadRequest, Unauthorized, Forbidden,
  /// Conflict, ValidationError, NotFound, InternalError) plus the two
  /// `POST /api/driver/auth/login` 403 examples (pending/suspended).
  static const Map<String, String> byMessage = {
    'invalid json body': 'طلب غير صالح',
    'invalid phone number or password': 'رقم الجوال أو كلمة المرور غير صحيحة',
    'customer access only': 'هذا الحساب غير مخصص لهذا التطبيق',
    'account already exists': 'الحساب موجود بالفعل',
    'validation failed': 'تحقق من البيانات المدخلة',
    'route not found': 'الخدمة المطلوبة غير متوفرة',
    'internal server error': 'حدث خطأ في الخادم، حاول لاحقاً',
    'your account is pending approval':
        'حسابك قيد المراجعة، سيتم تفعيله بعد الموافقة',
    'your account is suspended': 'تم إيقاف حسابك، يرجى التواصل مع الدعم',
  };

  /// `ErrorResponse.errors` reason literals — from the `ErrorResponse`
  /// schema example and the response examples across the spec. The
  /// reason text already embeds its field's meaning, so one flat table
  /// (keyed by reason, not by field+reason) covers every field.
  static const Map<String, String> byFieldReason = {
    'first_name is required': 'هذا الحقل مطلوب',
    'phone_number is required': 'رقم الجوال مطلوب',
    'phone_number is already registered': 'رقم الجوال مسجل مسبقاً',
    'password must be between 8 and 64 characters':
        'كلمة المرور يجب أن تكون بين 8 و64 حرفاً',
    'password must contain at least one number':
        'يجب أن تحتوي كلمة المرور على حرف ورقم على الأقل',
    'current status is pending; must be active':
        'حسابك قيد المراجعة، سيتم تفعيله بعد الموافقة',
    'current status is suspended; must be active':
        'تم إيقاف حسابك، يرجى التواصل مع الدعم',
  };

  /// Shown for a field whose reason is not in [byFieldReason] — the
  /// field is known to have failed, but the sentence describing why is
  /// not documented, so nothing about it is inferred.
  static const String unknownField = 'تحقق من هذا الحقل';
}
