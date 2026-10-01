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
  String get appUpdateAction => 'تحديث';

  @override
  String get appUpdateLater => 'لاحقًا';

  @override
  String get appUpdateOptionalTitle => 'يتوفر تحديث جديد';

  @override
  String get appUpdateRequiredTitle => 'التحديث مطلوب';

  @override
  String get appUpdateRequiredMessage =>
      'لم يعد هذا الإصدار من التطبيق مدعومًا. يرجى التحديث للمتابعة.';

  @override
  String get appMaintenanceTitle => 'التطبيق تحت الصيانة';

  @override
  String get appMaintenanceMessage => 'نعمل على تحسين التطبيق وسنعود قريبًا.';

  @override
  String appMaintenanceBackAt(String time) {
    return 'نعود: $time';
  }

  @override
  String get appMaintenanceAnyMinute => 'من المتوقع أن نعود بعد لحظات';

  @override
  String get appMaintenanceStillDown =>
      'ما زال التطبيق تحت الصيانة. حاول مرة أخرى بعد قليل.';

  @override
  String get appUpdateStoreFailed =>
      'تعذّر فتح المتجر. افتحه بنفسك وابحث عن Smart Taxi ثم حدّث التطبيق.';

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
  String get noData => 'لا توجد بيانات';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get loadMoreFailed => 'تعذّر تحميل المزيد';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navWallet => 'المحفظة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navCreateRequest => 'إنشاء طلب';

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
  String get phoneNumber => 'رقم الجوال';

  @override
  String get password => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

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
  String get roleCustomer => 'راكب';

  @override
  String get roleDriver => 'كابتن';

  @override
  String get roleCustomerDescription => 'احجز رحلاتك وتنقّل بسهولة وأمان';

  @override
  String get roleDriverDescription =>
      'سجّل الدخول إلى حساب الكابتن. الحسابات تُنشأ من قبل الشركة';

  @override
  String get forgotPasswordContactSupport => 'نسيت كلمة المرور؟ تواصل مع الدعم';

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
  String get logoutMessageCustomer =>
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
  String get cancelTripReasonChoosePrompt => 'اختر سبب إلغاء الرحلة';

  @override
  String get cancelReasonRequired => 'يرجى كتابة سبب الإلغاء';

  @override
  String get cancelReasonPick => 'اختر سبباً';

  @override
  String get cancelReasonWaitingTooLong => 'الانتظار طويل جداً';

  @override
  String get cancelReasonWrongLocation => 'الموقع خاطئ أو غير واضح';

  @override
  String get cancelReasonCannotReach => 'تعذّر التواصل مع الطرف الآخر';

  @override
  String get cancelReasonPlansChanged => 'تغيّرت الخطط';

  @override
  String get cancelReasonOther => 'سبب آخر';

  @override
  String get cancelReasonNoteHint => 'أضف ملاحظة (اختياري)';

  @override
  String get cancelReasonNoteRequiredHint => 'اشرح السبب';

  @override
  String get cancelLimitWarning => 'الإلغاء المتكرر قد يؤدي إلى حظر حسابك.';

  @override
  String get tripCancelled => 'تم إلغاء الرحلة';

  @override
  String get tripCancelledByCustomer => 'قام العميل بإلغاء الرحلة';

  @override
  String get tripCancelledByManager => 'تم إلغاء الرحلة من قبل الإدارة';

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
  String get presenceYouAreOnline => 'أنت متصل';

  @override
  String get presenceYouAreOffline => 'أنت غير متصل';

  @override
  String get presenceGoOnline => 'ابدأ العمل';

  @override
  String get presenceGoOffline => 'توقّف عن العمل';

  @override
  String get goOfflineConfirmTitle => 'التوقف عن العمل؟';

  @override
  String get goOfflineConfirmMessage =>
      'ستتوقف عن استقبال طلبات الرحلات، وستختفي العروض المعروضة الآن.';

  @override
  String get driverReconnectingStale =>
      'جارٍ إعادة الاتصال… قد تكون هذه العروض قديمة';

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
  String get fareCollectFromCustomer => 'المبلغ المطلوب من العميل';

  @override
  String get fareDetails => 'تفاصيل الأجرة';

  @override
  String get finishTripConfirmTitle => 'إنهاء الرحلة؟';

  @override
  String get finishTripConfirmMessage =>
      'ستُحتسب الأجرة بحسب المسار الذي قطعته حتى الآن، ثم تستلم الدفعة من العميل.';

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
  String get walletBalanceHint => 'تُخصم العمولات من هذا الرصيد';

  @override
  String get walletPreviousMonth => 'الشهر السابق';

  @override
  String get walletNextMonth => 'الشهر التالي';

  @override
  String get walletEarnings => 'أرباح الرحلات';

  @override
  String walletBalanceAfter(String amount) {
    return 'الرصيد بعد العملية: $amount';
  }

  @override
  String get txReward => 'مكافأة';

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
  String get profileStatusRejectedNote =>
      'لم تتم الموافقة على طلبك. تواصل مع الدعم لمعرفة التفاصيل';

  @override
  String get profileNoVehicle => 'لا توجد مركبة مسجّلة على حسابك بعد';

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
  String get priceUnavailable => 'السعر غير متوفر';

  @override
  String get noVehiclesAvailable =>
      'لا توجد مركبات متاحة لهذه الرحلة الآن. حاول مرة أخرى بعد قليل.';

  @override
  String requestVehicle(String name, String price) {
    return 'اطلب $name · $price';
  }

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
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyAgreePrefix => 'أوافق على ';

  @override
  String get privacyPolicyRequired =>
      'يجب الموافقة على سياسة الخصوصية لإنشاء حساب';

  @override
  String get privacyPolicyEmpty => 'لم يتم نشر سياسة الخصوصية بعد.';

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
  String get connectionErrorRetrying =>
      'تعذر الاتصال بالخادم — جاري إعادة المحاولة';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get errLoginRequired => 'يجب تسجيل الدخول';

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
  String get detailPaymentPaid => 'تم الدفع';

  @override
  String get detailPaymentUnpaid => 'بانتظار الدفع';

  @override
  String detailStopLabel(int number) {
    return 'محطة $number';
  }

  @override
  String get routeRecorded => 'تم تسجيل المسار';

  @override
  String get fareTripFare => 'أجرة الرحلة';

  @override
  String dateToday(String time) {
    return 'اليوم، $time';
  }

  @override
  String dateYesterday(String time) {
    return 'أمس، $time';
  }

  @override
  String get noRidesYet => 'لا توجد طلبات بعد';

  @override
  String get settingsSectionTrips => 'الرحلات';

  @override
  String get searchRadiusUnsaved => 'لم يتم الحفظ بعد';

  @override
  String get driverDeletionRejectedNoNote =>
      'لا توجد ملاحظة من المدير. يمكنك متابعة العمل أو إرسال طلب جديد.';

  @override
  String get settingsSectionPreferences => 'التفضيلات';

  @override
  String get settingsSectionHelp => 'المساعدة';

  @override
  String get discardChangesTitle => 'تجاهل التعديلات؟';

  @override
  String get discardChangesMessage =>
      'لديك تعديلات لم تُحفظ. إذا غادرت الآن فستضيع.';

  @override
  String get discardChangesConfirm => 'تجاهل';

  @override
  String get keepEditing => 'متابعة التعديل';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationNew => 'جديد';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String notificationsUnreadLabel(int count) {
    return 'الإشعارات، $count غير مقروء';
  }

  @override
  String get notificationsEmpty => 'لا توجد إشعارات';

  @override
  String get errPlacesSearch => 'تعذر البحث حالياً، حاول مرة أخرى';

  @override
  String get locationResolving => 'جارٍ تحديد العنوان...';

  @override
  String get locationUnresolved =>
      'لم نتمكن من تحديد عنوان لهذه النقطة. حرّك الدبوس وحاول مرة أخرى.';

  @override
  String get waitingAtPickup => 'الانتظار عند نقطة الانطلاق';

  @override
  String waitingFreeLeft(String time) {
    return 'الوقت المجاني المتبقي: $time';
  }

  @override
  String get liveFeeSoFar => 'الرسوم حتى الآن';

  @override
  String spokenMinutesSeconds(int minutes, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      two: 'دقيقتان',
      one: 'دقيقة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ثانية',
      two: 'ثانيتان',
      one: 'ثانية',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get waitingFreeOver => 'انتهى الوقت المجاني';

  @override
  String waitingFeeFinal(String amount) {
    return 'رسوم الانتظار: $amount';
  }

  @override
  String waitingRules(String minutes, String price) {
    return '$minutes دقائق مجانية، ثم $price لكل دقيقة';
  }

  @override
  String get fareDistanceFare => 'المسافة';

  @override
  String get fareBaseFare => 'الأجرة الأساسية';

  @override
  String get fareStopsFee => 'التوقفات';

  @override
  String get fareWaiting => 'الانتظار';

  @override
  String fareWaitingDetail(String minutes, String price) {
    return '$minutes د × $price';
  }

  @override
  String get fareTotal => 'الإجمالي';

  @override
  String get pauseTripPaused => 'الرحلة متوقفة مؤقتاً';

  @override
  String pauseIncludedLeft(String time) {
    return 'الوقت المشمول المتبقي: $time';
  }

  @override
  String get pauseIncludedOver => 'انتهى الوقت المشمول';

  @override
  String pauseRules(String base, String minutes, String price) {
    return '$base تشمل $minutes دقائق، ثم $price لكل دقيقة';
  }

  @override
  String pauseFeeTotal(String amount) {
    return 'التوقفات: $amount';
  }

  @override
  String get pauseStopLabel => 'التوقف أثناء الرحلة';

  @override
  String get driverPauseTrip => 'إيقاف الرحلة مؤقتاً';

  @override
  String get driverResumeTrip => 'متابعة الرحلة';

  @override
  String get farePauses => 'التوقفات';

  @override
  String get deleteAccount => 'حذف حسابي';

  @override
  String get deleteAccountTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountMessage =>
      'لا يمكن التراجع عن هذا الإجراء. سيتم مسح بياناتك الشخصية وعناوينك المحفوظة وإشعاراتك، وسيتم تسجيل خروجك من جميع الأجهزة. أدخل كلمة المرور للتأكيد.';

  @override
  String get deleteAccountPasswordLabel => 'كلمة المرور';

  @override
  String get deleteAccountConfirm => 'حذف نهائي';

  @override
  String get deleteAccountDone => 'تم حذف حسابك';

  @override
  String get errIncorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get driverDeleteMessage =>
      'سيقوم أحد المدراء بمراجعة طلبك. يمكنك متابعة العمل إلى حين الموافقة عليه، وبعدها سيتم مسح بياناتك الشخصية وتسجيل خروجك من جميع الأجهزة. أدخل كلمة المرور للتأكيد.';

  @override
  String get driverDeleteReasonLabel => 'السبب (اختياري)';

  @override
  String get driverDeleteReasonHint => 'لماذا تريد المغادرة؟';

  @override
  String get driverDeleteSubmit => 'إرسال الطلب';

  @override
  String get driverDeletionPendingTitle => 'طلب حذف الحساب قيد المراجعة';

  @override
  String get driverDeletionPendingBody =>
      'سيقوم أحد المدراء بمراجعة طلبك. يمكنك متابعة العمل إلى حين الموافقة عليه.';

  @override
  String get driverDeletionCancel => 'إلغاء الطلب';

  @override
  String get driverDeletionRejectedTitle => 'تم رفض طلب حذف الحساب';

  @override
  String get errAccountDeleted => 'تم حذف هذا الحساب';

  @override
  String get errDeleteActiveRide =>
      'لا يمكنك حذف حسابك أثناء وجود رحلة جارية. أنهِها أو ألغِها أولاً.';

  @override
  String get gpsRequiredTitle => 'فعّل الموقع (GPS)';

  @override
  String get gpsRequiredMessage =>
      'لا يمكن استخدام التطبيق أثناء إيقاف الموقع. فعّل الـ GPS للمتابعة.';

  @override
  String get gpsOpenSettings => 'فتح إعدادات الموقع';

  @override
  String get navRoute => 'مسار';

  @override
  String get routeStartNew => 'بداية مسار جديد';

  @override
  String get routeStartRecording => 'ابدأ التسجيل';

  @override
  String get routePause => 'إيقاف مؤقت';

  @override
  String get routeResume => 'استئناف';

  @override
  String get routeFinish => 'إنهاء المسار';

  @override
  String get routeIdleHint => 'مسار خاص، يُحفظ على هذا الهاتف فقط';

  @override
  String routeRecordingStatus(Object distance, Object time) {
    return 'جارٍ التسجيل · $time · $distance';
  }

  @override
  String get routeFinishConfirmTitle => 'إنهاء المسار؟';

  @override
  String get routeFinishConfirmMessage => 'سيتوقف تسجيل المسار وسترى ملخصه.';

  @override
  String get routeStartNewConfirmTitle => 'بدء مسار جديد؟';

  @override
  String get routeStartNewConfirmMessage =>
      'سيتم حذف المسار الحالي وملخصه من هذا الهاتف.';

  @override
  String get routeSummaryTitle => 'ملخص المسار';

  @override
  String get routeSummaryWaiting => 'الانتظار في البداية';

  @override
  String get routeSummaryTripTime => 'مدة الرحلة';

  @override
  String get routeSummaryStops => 'التوقفات (قهوة)';

  @override
  String get routeSummaryDriving => 'مدة القيادة';

  @override
  String get routeLocationDenied =>
      'يلزم السماح بالوصول إلى الموقع لتسجيل المسار';

  @override
  String farePausesDetail(String count, String time) {
    return '×$count · $time';
  }

  @override
  String get accountBlockedTitle => 'حسابك محظور مؤقتًا';

  @override
  String get accountBlockedCustomerMessage =>
      'لا يمكنك طلب رحلات جديدة أثناء الحظر. الرحلة الجارية حاليًا لا تتأثر.';

  @override
  String get accountBlockedDriverMessage =>
      'لن تصلك عروض رحلات جديدة أثناء الحظر. الرحلة الجارية حاليًا لا تتأثر.';

  @override
  String accountBlockedUntil(String date) {
    return 'محظور حتى $date';
  }

  @override
  String accountBlockedReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get noContactNumbers => 'لا توجد أرقام تواصل بعد.';

  @override
  String get whatsappNotAvailable => 'واتساب غير متاح على هذا الجهاز';

  @override
  String get callNotAvailable => 'الاتصال غير مدعوم على هذا الجهاز';

  @override
  String accountBlockedStrikes(int count, int limit) {
    return 'الإلغاءات: $count من $limit';
  }
}
