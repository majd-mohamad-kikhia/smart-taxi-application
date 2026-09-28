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

  /// Arabic label for every request field (body or query) the app itself
  /// ever sends, across every endpoint documented in swagger.json that
  /// this app calls (customer + driver — the spec's `/api/admin/*`
  /// endpoints have no UI in this app and are intentionally excluded).
  ///
  /// The API's exact validation-failure *wording* per field is mostly
  /// undocumented (only [byFieldReason]'s handful of literals are
  /// confirmed), so [ApiErrorHandler] never guesses that sentence — but
  /// the field *name* that failed is always given verbatim in the
  /// response's `errors` object, and is reliable. This table lets the
  /// handler name that field in Arabic instead of falling back to a
  /// fully generic "check your input" with no actionable detail.
  static const Map<String, String> fieldLabels = {
    // Auth (customer + driver share the same field names)
    'first_name': 'الاسم الأول',
    'last_name': 'الاسم الأخير',
    'phone_number': 'رقم الجوال',
    'password': 'كلمة المرور',
    'email': 'البريد الإلكتروني',
    'address': 'العنوان',
    'refresh_token': 'جلسة الدخول',
    // Complaints (customer + driver)
    'message': 'نص الرسالة',
    'subject': 'الموضوع',
    // Customer rides
    'vehicle_type_id': 'نوع المركبة',
    'pickup_lat': 'موقع الانطلاق',
    'pickup_lng': 'موقع الانطلاق',
    'pickup_address': 'عنوان الانطلاق',
    'dropoff_lat': 'موقع الوصول',
    'dropoff_lng': 'موقع الوصول',
    'dropoff_address': 'عنوان الوصول',
    'cancellation_reason': 'سبب الإلغاء',
    // Driver settings
    'search_radius_km': 'نطاق البحث',
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
  static const Map<String, String> fieldGuidance = {
    'password':
        'كلمة المرور يجب أن تكون بين 8 و64 حرفاً، بدون مسافات، وتحتوي على حرف ورقم على الأقل',
    'first_name': 'الاسم الأول يجب أن يكون بين حرفين و100 حرف',
    'last_name': 'الاسم الأخير يجب أن يكون بين حرفين و100 حرف',
    'message': 'نص الرسالة يجب أن يكون بين 5 و1000 حرف',
    'subject': 'الموضوع يجب ألا يتجاوز 150 حرفاً',
    'search_radius_km': 'نطاق البحث يجب أن يكون بين 0.1 و100 كم',
    'cancellation_reason': 'سبب الإلغاء يجب ألا يتجاوز 255 حرفاً',
  };
}
