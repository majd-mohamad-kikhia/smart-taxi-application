// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Smart Taxi';

  @override
  String get appTagline => 'Smart Taxi — مشوارك براحة وأمان';

  @override
  String appVersionFooter(String version) {
    return 'Smart Taxi الإصدار $version (2026)';
  }

  @override
  String get language => 'اللغة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get goBack => 'تراجع';

  @override
  String get save => 'حفظ';

  @override
  String get send => 'إرسال';

  @override
  String get delete => 'حذف';

  @override
  String get all => 'الكل';

  @override
  String get change => 'تغيير';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get confirmCancellation => 'تأكيد الإلغاء';

  @override
  String comingSoon(String label) {
    return '$label قريباً';
  }

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navWallet => 'المحفظة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navCreateRequest => 'انشاء طلب';

  @override
  String get navMyRequests => 'طلباتي';

  @override
  String distanceKm(String value) {
    return '$value كم';
  }

  @override
  String distanceKmToPickup(String value) {
    return '$value كم حتى الانطلاق';
  }

  @override
  String distanceKmVia(String value, String road) {
    return '$value كم عبر $road';
  }

  @override
  String durationMinutesShort(String minutes) {
    return '$minutes د';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String priceSyp(String amount) {
    return '$amount ل.س';
  }

  @override
  String priceLyd(String amount) {
    return '$amount د.ل';
  }

  @override
  String priceSar(String amount) {
    return '$amount ريال';
  }

  @override
  String get phoneNumber => 'رقم الجوال';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get address => 'العنوان';

  @override
  String get monthJan => 'يناير';

  @override
  String get monthFeb => 'فبراير';

  @override
  String get monthMar => 'مارس';

  @override
  String get monthApr => 'أبريل';

  @override
  String get monthMay => 'مايو';

  @override
  String get monthJun => 'يونيو';

  @override
  String get monthJul => 'يوليو';

  @override
  String get monthAug => 'أغسطس';

  @override
  String get monthSep => 'سبتمبر';

  @override
  String get monthOct => 'أكتوبر';

  @override
  String get monthNov => 'نوفمبر';

  @override
  String get monthDec => 'ديسمبر';

  @override
  String get timeAm => 'ص';

  @override
  String get timePm => 'م';

  @override
  String get errTimeout => 'انتهت مهلة الاتصال بالخادم';

  @override
  String get errNoInternet => 'تعذر الاتصال بالإنترنت، تحقق من اتصالك';

  @override
  String get errRequestCancelled => 'تم إلغاء الطلب';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get errServerUnreachable => 'تعذر الاتصال بالخادم';

  @override
  String get errNotConnected => 'غير متصل بالخادم';

  @override
  String get errInvalidRequest => 'طلب غير صالح';

  @override
  String get errWrongCredentials => 'رقم الجوال أو كلمة المرور غير صحيحة';

  @override
  String get errSessionExpired =>
      'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً';

  @override
  String get errAccountInactive => 'لا يمكن تسجيل الدخول، حسابك غير نشط حالياً';

  @override
  String get errNotAllowed => 'غير مصرح لك بهذا الإجراء';

  @override
  String get errNotFound => 'العنصر المطلوب غير موجود';

  @override
  String get errAccountExists => 'الحساب موجود بالفعل';

  @override
  String get errActionUnavailable =>
      'لا يمكن تنفيذ هذا الإجراء في الوقت الحالي';

  @override
  String get errCheckInput => 'تحقق من البيانات المدخلة';

  @override
  String get errServer => 'حدث خطأ في الخادم، حاول لاحقاً';

  @override
  String errCheckFields(String fields) {
    return 'تحقق من: $fields';
  }

  @override
  String get listSeparator => '، ';

  @override
  String get errCheckThisField => 'تحقق من هذا الحقل';

  @override
  String get errAccountNotForApp => 'هذا الحساب غير مخصص لهذا التطبيق';

  @override
  String get errServiceUnavailable => 'الخدمة المطلوبة غير متوفرة';

  @override
  String get errAccountPending =>
      'حسابك قيد المراجعة، سيتم تفعيله بعد الموافقة';

  @override
  String get errAccountSuspended => 'تم إيقاف حسابك، يرجى التواصل مع الدعم';

  @override
  String get errFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get errPhoneRequired => 'رقم الجوال مطلوب';

  @override
  String get errPhoneRegistered => 'رقم الجوال مسجل مسبقاً';

  @override
  String get errPasswordLength => 'كلمة المرور يجب أن تكون بين 8 و64 حرفاً';

  @override
  String get errPasswordNeedsNumber =>
      'يجب أن تحتوي كلمة المرور على حرف ورقم على الأقل';

  @override
  String get fieldFirstName => 'الاسم الأول';

  @override
  String get fieldLastName => 'الاسم الأخير';

  @override
  String get fieldSession => 'جلسة الدخول';

  @override
  String get fieldMessage => 'نص الرسالة';

  @override
  String get fieldSubject => 'الموضوع';

  @override
  String get fieldVehicleType => 'نوع المركبة';

  @override
  String get fieldPickupLocation => 'موقع الانطلاق';

  @override
  String get fieldPickupAddress => 'عنوان الانطلاق';

  @override
  String get fieldDropoffLocation => 'موقع الوصول';

  @override
  String get fieldDropoffAddress => 'عنوان الوصول';

  @override
  String get fieldCancelReason => 'سبب الإلغاء';

  @override
  String get fieldSearchRadius => 'نطاق البحث';

  @override
  String get guidePassword =>
      'كلمة المرور يجب أن تكون بين 8 و64 حرفاً، بدون مسافات، وتحتوي على حرف ورقم على الأقل';

  @override
  String get guideFirstName => 'الاسم الأول يجب أن يكون بين حرفين و100 حرف';

  @override
  String get guideLastName => 'الاسم الأخير يجب أن يكون بين حرفين و100 حرف';

  @override
  String get guideMessage => 'نص الرسالة يجب أن يكون بين 5 و1000 حرف';

  @override
  String get guideSubject => 'الموضوع يجب ألا يتجاوز 150 حرفاً';

  @override
  String get guideSearchRadius => 'نطاق البحث يجب أن يكون بين 0.1 و100 كم';

  @override
  String get guideCancelReason => 'سبب الإلغاء يجب ألا يتجاوز 255 حرفاً';

  @override
  String get valPhone => 'أدخل رقم جوال صحيح';

  @override
  String get valPasswordRequired => 'أدخل كلمة المرور';

  @override
  String get valPasswordRule =>
      'كلمة المرور 8 أحرف على الأقل وتحتوي حرفاً ورقماً';

  @override
  String get valPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get valNameLetters => 'حروف فقط، بحد أدنى حرفين';

  @override
  String get valEmailInvalid => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get errLocationServiceOff => 'خدمة الموقع غير مفعّلة على جهازك';

  @override
  String get errLocationDenied => 'تم رفض إذن الوصول إلى الموقع';

  @override
  String get errEnableGps => 'يرجى تفعيل خدمة الموقع (GPS) في إعدادات الجهاز';

  @override
  String get errEnableLocationPermission =>
      'يرجى تفعيل صلاحية الموقع للتطبيق من إعدادات الجهاز';

  @override
  String get roleRider => 'راكب';

  @override
  String get roleDriver => 'كابتن';

  @override
  String get roleRiderDescription => 'احجز رحلاتك وتنقّل بسهولة وأمان';

  @override
  String get roleDriverDescription => 'انضم كسائق وابدأ استقبال الرحلات';

  @override
  String get logoutTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirm => 'تسجيل الخروج';

  @override
  String get logoutFromAccount => 'تسجيل الخروج من الحساب';

  @override
  String get logoutMessageDriver =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟';

  @override
  String get logoutMessageRider =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟ ستحتاج لتسجيل الدخول مجدداً للمتابعة.';

  @override
  String get complaintSend => 'إرسال بلاغ';

  @override
  String get complaintSubjectLabel => 'الموضوع (اختياري)';

  @override
  String get complaintSubjectHint => 'عنوان مختصر للبلاغ';

  @override
  String get complaintDetailsLabel => 'التفاصيل';

  @override
  String get complaintDetailsHint => 'اكتب تفاصيل البلاغ هنا...';

  @override
  String get complaintMinLength => 'يرجى كتابة 5 أحرف على الأقل';

  @override
  String get complaintMaxLength => 'الحد الأقصى 1000 حرف';

  @override
  String get complaintSendFailed => 'تعذر إرسال البلاغ';

  @override
  String get complaintSent => 'تم إرسال البلاغ بنجاح';

  @override
  String get cancelTrip => 'إلغاء الرحلة';

  @override
  String get cancelTripReasonPrompt => 'يرجى كتابة سبب إلغاء الرحلة';

  @override
  String get cancelReasonRequired => 'يرجى كتابة سبب الإلغاء';

  @override
  String get cancelReasonHint => 'اكتب السبب هنا...';

  @override
  String get tripCancelled => 'تم إلغاء الرحلة';

  @override
  String get walletComingSoon => 'المحفظة قريباً';

  @override
  String get notificationsChannelName => 'الإشعارات';

  @override
  String get notificationsChannelDescription =>
      'تحديثات الرحلات والعروض والتنبيهات';

  @override
  String get welcomeToApp => 'أهلاً بك في Smart Taxi';

  @override
  String get chooseAccountType => 'اختر نوع حسابك للمتابعة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'أدخل بياناتك للمتابعة إلى Smart Taxi';

  @override
  String get driverSignInTitle => 'تسجيل دخول الكباتن';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signUpSubtitle => 'أدخل بياناتك لإنشاء حساب جديد في Smart Taxi';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get hasAccount => 'لديك حساب بالفعل؟';

  @override
  String get firstNameLabel => 'الاسم';

  @override
  String get firstNameHint => 'مثال: محمد';

  @override
  String get lastNameLabel => 'الكنية';

  @override
  String get lastNameHint => 'مثال: العتيبي';

  @override
  String get driverStatusPending => 'قيد المراجعة';

  @override
  String get driverStatusActive => 'نشط';

  @override
  String get driverStatusSuspended => 'موقوف';

  @override
  String get driverStatusRejected => 'مرفوض';

  @override
  String get searchRadiusTitle => 'نطاق البحث عن الرحلات';

  @override
  String get searchRadiusDescription =>
      'أقصى مسافة لاستقبال طلبات الرحلات القريبة منك';

  @override
  String get searchRadiusSaved => 'تم حفظ نطاق البحث';

  @override
  String get searchRadiusSaveFailed => 'تعذر حفظ نطاق البحث';

  @override
  String get driverAcceptTrip => 'قبول الرحلة';

  @override
  String get driverAcceptTripFailed => 'تعذر قبول الرحلة';

  @override
  String get driverGoOnlineHint => 'فعّل الظهور كمتاح لعرض طلبات الرحلات';

  @override
  String get driverWaitingForOrders => 'بانتظار طلبات رحلات جديدة...';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get driverAvailabilityPaused => 'الظهور كمتاح متوقف حتى تفعيل الحساب';

  @override
  String get presenceOnline => 'متاح لاستقبال الرحلات';

  @override
  String get presenceConnecting => 'جاري الاتصال...';

  @override
  String get presenceOffline => 'غير متاح';

  @override
  String get locationSharingTitle => 'أنت متاح لاستقبال الرحلات';

  @override
  String get locationSharingText => 'يتم مشاركة موقعك مع الإدارة أثناء توفرك';

  @override
  String get locationSharingChannel => 'مشاركة الموقع';

  @override
  String get driverGoToPickup => 'التوجه لنقطة الانطلاق';

  @override
  String get driverStartedTheTrip => 'بدء الرحلة';

  @override
  String get driverArrivalReported => 'تم الإبلاغ عن الوصول';

  @override
  String get paymentReceived => 'تم استلام الدفعة';

  @override
  String get paymentConfirmedTitle => 'تم تأكيد الدفع';

  @override
  String get paymentTotalPaid => 'المبلغ المدفوع';

  @override
  String get paymentYourShare => 'حصتك';

  @override
  String get paymentCommissionDeducted => 'العمولة المخصومة من المحفظة';

  @override
  String get paymentWalletBalance => 'رصيد المحفظة';

  @override
  String get fareSummaryTitle => 'اكتملت الرحلة';

  @override
  String get fareFinalPrice => 'السعر النهائي';

  @override
  String get fareEstimatedPrice => 'السعر التقديري';

  @override
  String get fareDifference => 'الفرق';

  @override
  String get fareDistanceDriven => 'المسافة المقطوعة';

  @override
  String get fareCommission => 'العمولة';

  @override
  String get fareYourEarning => 'أرباحك';

  @override
  String get done => 'تم';

  @override
  String get driverReportArrival => 'لقد وصلت';

  @override
  String get driverFinishTrip => 'إنهاء الرحلة';

  @override
  String get walletFines => 'الغرامات الإدارية';

  @override
  String get walletNoFines => 'لا توجد غرامات';

  @override
  String get walletTotalCommissions => 'العمولات الكلية';

  @override
  String get walletBonuses => 'المكافآت';

  @override
  String get walletCompletedTrips => 'عدد المشاوير المكتملة';

  @override
  String walletTripsCount(String count) {
    return '$count رحلة';
  }

  @override
  String get walletMonthlyIncome => 'إجمالي دخل الشهر';

  @override
  String get txTopup => 'شحن رصيد';

  @override
  String get txCommission => 'عمولة';

  @override
  String get txPenalty => 'غرامة';

  @override
  String get txCompensation => 'تعويض';

  @override
  String get profileName => 'الاسم';

  @override
  String get profileRating => 'التقييم';

  @override
  String get profileNoRatingYet => 'لا يوجد بعد';

  @override
  String get profileWalletBalance => 'رصيد المحفظة';

  @override
  String get vehicleInfo => 'بيانات المركبة';

  @override
  String get vehicleType => 'النوع';

  @override
  String get vehicleModel => 'الموديل';

  @override
  String get vehicleColor => 'اللون';

  @override
  String get vehiclePlate => 'رقم اللوحة';

  @override
  String get settingsSectionAccount => 'الحساب والمدفوعات';

  @override
  String get settingsSectionSafety => 'الأمان والدعم';

  @override
  String get settingsFavoritesTitle => 'الأماكن المفضلة والمحفوظة';

  @override
  String get settingsFavoritesSubtitle => 'المنزل، العمل، استراحة (3 مواقع)';

  @override
  String get settingsSupportTitle => 'المساعدة والدعم الفني';

  @override
  String get settingsSupportSubtitle =>
      'محادثة مباشرة أو اتصال على مدار الساعة';

  @override
  String get settingsTermsTitle => 'الشروط والخصوصية';

  @override
  String get settingsTermsSubtitle => 'سياسة الاستخدام وحماية البيانات';

  @override
  String get favoritePlaces => 'الأماكن المفضلة';

  @override
  String get editPersonalInfo => 'تعديل البيانات الشخصية';

  @override
  String get profileSaved => 'تم حفظ البيانات بنجاح';

  @override
  String get errLoadData => 'تعذر تحميل البيانات';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get firstNameEditHint => 'أدخل الاسم الأول';

  @override
  String get familyNameLabel => 'اسم العائلة';

  @override
  String get familyNameHint => 'أدخل اسم العائلة';

  @override
  String get phoneEditHint => 'أدخل رقم الجوال';

  @override
  String get emailOptionalLabel => 'البريد الإلكتروني (اختياري)';

  @override
  String get addressOptionalLabel => 'العنوان (اختياري)';

  @override
  String get addressHint => 'المدينة أو الحي';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء النور';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting، $name 👋';
  }

  @override
  String greetingOnly(String greeting) {
    return '$greeting 👋';
  }

  @override
  String get homeRequestInProgress => 'طلبك قيد التنفيذ الآن';

  @override
  String get homeWhereTo => 'إلى أين تريد الذهاب اليوم؟';

  @override
  String get fromLabel => 'من';

  @override
  String get toLabel => 'إلى';

  @override
  String get pickPickupPoint => 'اختر نقطة الانطلاق';

  @override
  String get pickDestination => 'اختر وجهتك';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get search => 'بحث';

  @override
  String get pickVehicleType => 'اختر نوع المركبة';

  @override
  String get priceEstimateNote =>
      'السعر تقديري وقد يختلف حسب المسار الفعلي للرحلة';

  @override
  String get notAvailableNow => 'غير متاح حالياً';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get searchPlaceHint => 'ابحث عن مكان...';

  @override
  String get mapLocationFallback => 'موقع على الخريطة';

  @override
  String get priceEstimateTag => '(سعر تقديري)';

  @override
  String get rideAwaitingDriver => 'بانتظار وصول السائق';

  @override
  String get rideAccepted => 'تم قبول طلبك';

  @override
  String get rideDriverArrived => 'السائق وصل';

  @override
  String get rideInProgress => 'الرحلة جارية';

  @override
  String get rideCompleted => 'اكتملت الرحلة';

  @override
  String get rideRequestCancelled => 'تم إلغاء الطلب';

  @override
  String get trackDriverOnTheWay => 'السائق في الطريق إليك';

  @override
  String get trackDriverAtPickup => 'السائق وصل لنقطة الانطلاق';

  @override
  String get tripCompletedSuccess => 'اكتملت الرحلة بنجاح';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get termsAgreePrefix => 'أوافق على ';

  @override
  String get termsRequired => 'يجب الموافقة على الشروط والأحكام لإنشاء حساب';

  @override
  String get termsEmpty => 'لم يتم نشر الشروط والأحكام بعد.';

  @override
  String get close => 'إغلاق';

  @override
  String get payDriverTitle => 'اكتملت الرحلة';

  @override
  String get payDriverMessage => 'يرجى دفع المبلغ للسائق';

  @override
  String get payDriverWaiting => 'بانتظار تأكيد السائق لاستلام الدفعة';

  @override
  String get trackTrip => 'تتبع الرحلة';

  @override
  String get cancelTripQuestion => 'إلغاء الرحلة؟';

  @override
  String get cancelTripMessage =>
      'هل أنت متأكد من رغبتك في إلغاء هذه الرحلة؟ لن يتم خصم أي رسوم إذا ألغيت خلال دقيقتين.';

  @override
  String get tripSafety => 'أمان الرحلة';

  @override
  String get actionCall => 'اتصال';

  @override
  String get actionChat => 'محادثة';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get safeTripTitle => 'رحلة آمنة وموثقة';

  @override
  String get safeTripActive => 'تتبع المسار ومشاركة الموقع مفعلين';

  @override
  String get safeTripActivating => 'ميزات الأمان قيد التفعيل';

  @override
  String get connectionErrorRetrying =>
      'تعذر الاتصال بالخادم — جاري إعادة المحاولة';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get errLoginRequired => 'يجب تسجيل الدخول';

  @override
  String get pickupPointSelected => 'نقطة الالتقاء المحددة';

  @override
  String paymentMethodValue(String method) {
    return 'طريقة الدفع: $method';
  }

  @override
  String captainCertified(String trips) {
    return 'كابتن معتمد • $trips+ رحلة';
  }

  @override
  String get liveCaptainOnTheWay => 'الكابتن في الطريق إليك';

  @override
  String get liveArrived => 'الكابتن وصل لنقطة الالتقاء';

  @override
  String get liveInProgress => 'أنت في الطريق إلى الوجهة';

  @override
  String get liveCompleted => 'وصلت إلى وجهتك';

  @override
  String liveEtaOnly(String minutes) {
    return 'الوصول المتوقع: $minutes دقائق فقط';
  }

  @override
  String get liveArrivedSub => 'الكابتن بانتظارك عند نقطة الالتقاء';

  @override
  String liveRemaining(String minutes) {
    return 'المدة المتبقية: $minutes دقائق';
  }

  @override
  String get liveThanks => 'شكراً لاستخدامك Smart Taxi';

  @override
  String get mockCaptainName => 'عبدالرحمن الشمري';

  @override
  String get mockVehicleModel => 'تويوتا كامري 2024';

  @override
  String get mockVehicleColor => 'رمادي';

  @override
  String get mockPlateLetters => 'أ ب ج';

  @override
  String get mockPickupTitle => 'أمام بوابة المجمع الرئيسية';

  @override
  String get mockPickupSubtitle => 'طريق الملك فهد، مقابل النافورة';

  @override
  String get mockPaymentWallet => 'محفظة Smart Taxi';

  @override
  String get rideStatusPending => 'قيد الانتظار';

  @override
  String get rideStatusAcceptedHist => 'تم قبول الطلب';

  @override
  String get rideStatusArrivedHist => 'وصل السائق';

  @override
  String get rideStatusInProgressHist => 'جارية';

  @override
  String get rideStatusCompletedHist => 'مكتملة';

  @override
  String get rideStatusCancelledHist => 'ملغاة';

  @override
  String rideDetailsTitle(String id) {
    return 'تفاصيل الطلب #$id';
  }

  @override
  String get rideDrivenRouteTitle => 'المسار الذي سلكه السائق';

  @override
  String get errLoadDetails => 'تعذر تحميل التفاصيل';

  @override
  String get cancelledByCustomer => 'العميل';

  @override
  String get cancelledByDriver => 'السائق';

  @override
  String get cancelledByManager => 'الإدارة';

  @override
  String get detailRequestedAt => 'تاريخ الطلب';

  @override
  String get detailAcceptedAt => 'وقت القبول';

  @override
  String get detailStartedAt => 'بدء الرحلة';

  @override
  String get detailCompletedAt => 'انتهاء الرحلة';

  @override
  String get detailCancelledAt => 'وقت الإلغاء';

  @override
  String get detailCancelledBy => 'ألغيت بواسطة';

  @override
  String get detailDistance => 'المسافة';

  @override
  String get detailEstimatedDuration => 'المدة التقديرية';

  @override
  String get detailStopsFee => 'رسوم التوقفات';

  @override
  String get noRidesYet => 'لا توجد طلبات بعد';

  @override
  String get favoriteAddresses => 'العناوين المفضلة';

  @override
  String get favAddressDeleted => 'تم حذف العنوان';

  @override
  String get favSelectOnMapSoon => 'تحديد على الخريطة قريباً';

  @override
  String get favSearchByNameSoon => 'البحث بالاسم قريباً';

  @override
  String favPlacesCount(String count) {
    return '$count أماكن';
  }

  @override
  String get favSort => 'ترتيب';

  @override
  String get favEmpty => 'لا توجد عناوين محفوظة';

  @override
  String favEditSoon(String name) {
    return 'تعديل $name قريباً';
  }

  @override
  String get favCurrentSaved => 'تم حفظ الموقع الحالي';

  @override
  String get favDeleteTitle => 'حذف العنوان؟';

  @override
  String favDeleteMessage(String name) {
    return 'هل تريد حذف \"$name\" من عناوينك المفضلة؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get favMyCurrentLocation => 'موقعي الحالي';

  @override
  String get favDefault => 'افتراضي';

  @override
  String get favOrderRideHere => 'طلب مشوار إلى هنا الآن';

  @override
  String get favFavoritePlace => 'موقع مفضل';

  @override
  String get favSaveCurrent => 'حفظ موقعك الحالي';

  @override
  String favNearYou(String area) {
    return 'أنت الآن بالقرب من: $area';
  }

  @override
  String get favSaveOneTap => 'احفظ موقعي الحالي بنقرة واحدة';

  @override
  String get favAddNew => 'إضافة عنوان جديد';

  @override
  String get favAddNewSubtitle => 'احفظ وجهاتك المتكررة للوصول السريع';

  @override
  String get favSelectOnMap => 'التحديد على الخريطة';

  @override
  String get favSearchByName => 'البحث بالاسم';

  @override
  String get favMockHomeName => 'المنزل';

  @override
  String get favMockHomeAddress =>
      'حي العليا، شارع الأمير سلطان، فيلا 14، الرياض';

  @override
  String get favMockHomeNote => 'البوابة الجانبية الرمادية';

  @override
  String get favMockWorkName => 'العمل';

  @override
  String get favMockWorkAddress => 'برج المملكة، طريق الملك فهد، الرياض';

  @override
  String get favMockWorkNote => 'موقف قبو P2';

  @override
  String get favMockGymName => 'النادي الرياضي';

  @override
  String get favMockGymAddress => 'حي الملقا، شارع أنس بن مالك، الرياض';

  @override
  String get favMockMomName => 'بيت الوالدة';

  @override
  String get favMockMomAddress => 'حي الياسمين، شارع التخصصي، الرياض';

  @override
  String get favMockCurrentArea => 'مجمع السدرة، الرياض';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات';

  @override
  String get errNotificationsLoad => 'تعذر تحميل الإشعارات';

  @override
  String get errPlacesSearch => 'تعذر البحث حالياً، حاول مرة أخرى';

  @override
  String get mockNotif1Title => 'الكابتن ماجد في الطريق إليك';

  @override
  String get mockNotif1Message =>
      'سيصل كابتنك خلال 3 دقائق تقريباً، جهّز نفسك للانطلاق.';

  @override
  String get mockNotif2Title => 'خصم 20% على مشاويرك';

  @override
  String get mockNotif2Message =>
      'استخدم الرمز الترويجي \"SMARTTAXI20\" عند الحجز هذا الأسبوع.';

  @override
  String get mockNotif3Title => 'تم خصم المبلغ بنجاح';

  @override
  String get mockNotif3Message =>
      'تم خصم 38.50 ل.س من محفظتك مقابل رحلتك الأخيرة.';

  @override
  String get mockNotif4Title => 'وصلت إلى وجهتك بنجاح';

  @override
  String get mockNotif4Message =>
      'نتمنى أن تكون قد استمتعت برحلتك معنا. لا تنسَ تقييم الكابتن.';

  @override
  String get mockNotif5Title => 'عرض خاص لعملاء Smart Taxi';

  @override
  String get mockNotif5Message =>
      'احصل على رحلة مجانية عند دعوة 3 أصدقاء للتطبيق.';

  @override
  String get mockNotif6Title => 'تحديث سياسة الخصوصية';

  @override
  String get mockNotif6Message =>
      'قمنا بتحديث سياسة الخصوصية وشروط الاستخدام الخاصة بالتطبيق.';

  @override
  String get bookingHeaderConfirm => 'تأكيد الطلب';

  @override
  String get bookingCertifiedCaptains => 'كبائن معتمدون ومرخصون';

  @override
  String get bookingInstantMatch => 'تأكيد ومطابقة فورية';

  @override
  String bookingConfirmRide(String category) {
    return 'تأكيد طلب مشوار $category';
  }

  @override
  String get bookingAgreePrefix => 'بالضغط على تأكيد، أنت توافق على ';

  @override
  String get bookingTerms => 'شروط الخدمة';

  @override
  String get bookingAgreeAnd => ' و';

  @override
  String get bookingPrivacy => 'سياسة الخصوصية';

  @override
  String get bookingAgreeSuffix => ' الخاصة بـ Smart Taxi';

  @override
  String bookingConfirmed(String category) {
    return 'تم تأكيد طلب مشوار $category بنجاح';
  }

  @override
  String get bookingChooseType => 'اختر نوع المشوار';

  @override
  String bookingCategoriesAvailable(String count) {
    return '$count فئات متوفرة';
  }

  @override
  String get bookingCompareSpecs => 'مقارنة المواصفات';

  @override
  String get bookingPaymentMethod => 'طريقة الدفع';

  @override
  String get bookingCaptainNote => 'ملاحظة للكابتن';

  @override
  String get bookingAddNote => 'أضف ملاحظة...';

  @override
  String get bookingDragMap => 'اسحب الخريطة لتعديل نقطة الالتقاء بدقة';

  @override
  String bookingCapacityEta(String capacity, String minutes) {
    return '$capacity ركاب • $minutes د';
  }

  @override
  String bookingEtaMinutes(String minutes) {
    return '$minutes دقائق';
  }

  @override
  String get bookingMockPickup => 'حي الصحافة، طريق العليا العام';

  @override
  String get bookingMockDestination => 'واجهة الرياض (Riyadh Front) - بوابة 4';

  @override
  String get bookingMockViaRoad => 'طريق الثمامة';

  @override
  String get catEconomy => 'اقتصادي';

  @override
  String get catEconomyBadge => 'الأكثر توفيراً';

  @override
  String get catComfort => 'مريح';

  @override
  String get catFamilyXl => 'عائلي XL';

  @override
  String get bookingPaymentWallet => 'محفظة';

  @override
  String get bookingMockNote => 'بدون اتصال - التك...';

  @override
  String get bookingMockPromo => 'تم تطبيق كود ترحيبي Smart Taxi (خصم 15%)';

  @override
  String get locationResolving => 'جارٍ تحديد العنوان...';

  @override
  String get locationUnresolved =>
      'لم نتمكن من تحديد عنوان لهذه النقطة. حرّك الدبوس وحاول مرة أخرى.';
}
