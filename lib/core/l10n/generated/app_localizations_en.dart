// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Smart Taxi';

  @override
  String get appTagline => 'Smart Taxi — your ride, easy and safe';

  @override
  String appVersionFooter(String version) {
    return 'Smart Taxi version $version (2026)';
  }

  @override
  String get language => 'Language';

  @override
  String get retry => 'Retry';

  @override
  String get appUpdateAction => 'Update';

  @override
  String get appUpdateLater => 'Later';

  @override
  String get appUpdateOptionalTitle => 'A new update is available';

  @override
  String get appUpdateRequiredTitle => 'Update required';

  @override
  String get appUpdateRequiredMessage =>
      'This version of the app is no longer supported. Please update to continue.';

  @override
  String get appMaintenanceTitle => 'Under maintenance';

  @override
  String get appMaintenanceMessage =>
      'We\'re improving the app and will be back shortly.';

  @override
  String appMaintenanceBackAt(String time) {
    return 'Back at $time';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get goBack => 'Go back';

  @override
  String get save => 'Save';

  @override
  String get send => 'Send';

  @override
  String get delete => 'Delete';

  @override
  String get all => 'All';

  @override
  String get change => 'Change';

  @override
  String get continueLabel => 'Continue';

  @override
  String get confirmCancellation => 'Confirm cancellation';

  @override
  String get noData => 'No data';

  @override
  String get navHome => 'Home';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCreateRequest => 'New ride';

  @override
  String get navMyRequests => 'My rides';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceKmToPickup(String value) {
    return '$value km to pickup';
  }

  @override
  String durationMinutesShort(String minutes) {
    return '$minutes min';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String priceSyp(String amount) {
    return '$amount SYP';
  }

  @override
  String priceLyd(String amount) {
    return '$amount LYD';
  }

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get errTimeout => 'The connection to the server timed out';

  @override
  String get errNoInternet =>
      'Couldn\'t reach the internet, check your connection';

  @override
  String get errRequestCancelled => 'The request was cancelled';

  @override
  String get errUnexpected => 'An unexpected error occurred';

  @override
  String get errServerUnreachable => 'Couldn\'t connect to the server';

  @override
  String get errNotConnected => 'Not connected to the server';

  @override
  String get errInvalidRequest => 'Invalid request';

  @override
  String get errWrongCredentials => 'Incorrect phone number or password';

  @override
  String get errSessionExpired =>
      'Your session has expired, please sign in again';

  @override
  String get errAccountInactive =>
      'You can\'t sign in, your account is not active right now';

  @override
  String get errNotAllowed => 'You aren\'t allowed to do this';

  @override
  String get errNotFound => 'The requested item was not found';

  @override
  String get errAccountExists => 'This account already exists';

  @override
  String get errActionUnavailable =>
      'This action can\'t be performed right now';

  @override
  String get errCheckInput => 'Check the entered data';

  @override
  String get errServer => 'A server error occurred, try again later';

  @override
  String errCheckFields(String fields) {
    return 'Check: $fields';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get errCheckThisField => 'Check this field';

  @override
  String get errAccountNotForApp => 'This account isn\'t meant for this app';

  @override
  String get errServiceUnavailable => 'The requested service is not available';

  @override
  String get errAccountPending =>
      'Your account is under review and will be activated once approved';

  @override
  String get errAccountSuspended =>
      'Your account has been suspended, please contact support';

  @override
  String get errFieldRequired => 'This field is required';

  @override
  String get errPhoneRequired => 'Phone number is required';

  @override
  String get errPhoneRegistered => 'This phone number is already registered';

  @override
  String get errPasswordLength =>
      'Password must be between 8 and 64 characters';

  @override
  String get errPasswordNeedsNumber =>
      'Password must contain at least one letter and one number';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldSession => 'Login session';

  @override
  String get fieldMessage => 'Message text';

  @override
  String get fieldSubject => 'Subject';

  @override
  String get fieldVehicleType => 'Vehicle type';

  @override
  String get fieldPickupLocation => 'Pickup location';

  @override
  String get fieldPickupAddress => 'Pickup address';

  @override
  String get fieldDropoffLocation => 'Drop-off location';

  @override
  String get fieldDropoffAddress => 'Drop-off address';

  @override
  String get fieldCancelReason => 'Cancellation reason';

  @override
  String get fieldSearchRadius => 'Search radius';

  @override
  String get guidePassword =>
      'Password must be 8–64 characters, with no spaces, and include at least one letter and one number';

  @override
  String get guideFirstName =>
      'First name must be between 2 and 100 characters';

  @override
  String get guideLastName => 'Last name must be between 2 and 100 characters';

  @override
  String get guideMessage => 'Message must be between 5 and 1000 characters';

  @override
  String get guideSubject => 'Subject must not exceed 150 characters';

  @override
  String get guideSearchRadius =>
      'Search radius must be between 0.1 and 100 km';

  @override
  String get guideCancelReason =>
      'Cancellation reason must not exceed 255 characters';

  @override
  String get valPhone => 'Enter a valid phone number';

  @override
  String get valPasswordRequired => 'Enter your password';

  @override
  String get valPasswordRule =>
      'Password must be at least 8 characters and contain a letter and a number';

  @override
  String get valPasswordMismatch => 'Passwords don\'t match';

  @override
  String get valNameLetters => 'Letters only, at least 2 characters';

  @override
  String get valEmailInvalid => 'Enter a valid email address';

  @override
  String get errLocationServiceOff =>
      'Location services are turned off on your device';

  @override
  String get errLocationDenied => 'Location permission was denied';

  @override
  String get errEnableGps =>
      'Please turn on location services (GPS) in your device settings';

  @override
  String get errEnableLocationPermission =>
      'Please allow the app to use your location in your device settings';

  @override
  String get roleRider => 'Rider';

  @override
  String get roleDriver => 'Captain';

  @override
  String get roleRiderDescription =>
      'Book your rides and get around easily and safely';

  @override
  String get roleDriverDescription =>
      'Join as a driver and start receiving rides';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutConfirm => 'Log out';

  @override
  String get logoutFromAccount => 'Log out of account';

  @override
  String get logoutMessageDriver =>
      'Are you sure you want to log out of your account?';

  @override
  String get logoutMessageRider =>
      'Are you sure you want to log out of your account? You\'ll need to sign in again to continue.';

  @override
  String get complaintSend => 'Send a report';

  @override
  String get complaintSubjectLabel => 'Subject (optional)';

  @override
  String get complaintSubjectHint => 'A short title for the report';

  @override
  String get complaintDetailsLabel => 'Details';

  @override
  String get complaintDetailsHint => 'Write the report details here...';

  @override
  String get complaintMinLength => 'Please write at least 5 characters';

  @override
  String get complaintMaxLength => 'Maximum 1000 characters';

  @override
  String get complaintSendFailed => 'Couldn\'t send the report';

  @override
  String get complaintSent => 'Report sent successfully';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String get cancelTripReasonPrompt =>
      'Please write the reason for cancelling the trip';

  @override
  String get cancelReasonRequired => 'Please write the cancellation reason';

  @override
  String get cancelReasonHint => 'Write the reason here...';

  @override
  String get tripCancelled => 'The trip was cancelled';

  @override
  String get tripCancelledByCustomer => 'The customer cancelled the trip';

  @override
  String get tripCancelledByManager => 'The trip was cancelled by the manager';

  @override
  String get notificationsChannelName => 'Notifications';

  @override
  String get notificationsChannelDescription =>
      'Ride updates, offers and alerts';

  @override
  String get welcomeToApp => 'Welcome to Smart Taxi';

  @override
  String get chooseAccountType => 'Choose your account type to continue';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Enter your details to continue to Smart Taxi';

  @override
  String get driverSignInTitle => 'Captain sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signUpSubtitle =>
      'Enter your details to create a new Smart Taxi account';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameHint => 'e.g. Mohammed';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get lastNameHint => 'e.g. Alotaibi';

  @override
  String get driverStatusPending => 'Under review';

  @override
  String get driverStatusActive => 'Active';

  @override
  String get driverStatusSuspended => 'Suspended';

  @override
  String get driverStatusRejected => 'Rejected';

  @override
  String get searchRadiusTitle => 'Trip search radius';

  @override
  String get searchRadiusDescription =>
      'The maximum distance for receiving nearby trip requests';

  @override
  String get searchRadiusSaved => 'Search radius saved';

  @override
  String get searchRadiusSaveFailed => 'Couldn\'t save the search radius';

  @override
  String get driverAcceptTrip => 'Accept trip';

  @override
  String get driverAcceptTripFailed => 'Couldn\'t accept the trip';

  @override
  String get driverGoOnlineHint => 'Go online to see trip requests';

  @override
  String get driverWaitingForOrders => 'Waiting for new trip requests...';

  @override
  String get openSettings => 'Open settings';

  @override
  String get driverAvailabilityPaused =>
      'Going online is disabled until your account is activated';

  @override
  String get presenceOnline => 'Available for trips';

  @override
  String get presenceConnecting => 'Connecting...';

  @override
  String get presenceOffline => 'Unavailable';

  @override
  String get locationSharingTitle => 'You\'re available for trips';

  @override
  String get locationSharingText =>
      'Your location is shared with the dispatcher while you\'re available';

  @override
  String get locationSharingChannel => 'Location sharing';

  @override
  String get driverGoToPickup => 'Head to the pickup point';

  @override
  String get driverStartedTheTrip => 'Start the trip';

  @override
  String get driverArrivalReported => 'Arrival reported';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String get paymentConfirmedTitle => 'Payment confirmed';

  @override
  String get paymentTotalPaid => 'Total paid';

  @override
  String get paymentYourShare => 'Your share';

  @override
  String get paymentCommissionDeducted => 'Commission deducted from wallet';

  @override
  String get paymentWalletBalance => 'Wallet balance';

  @override
  String get fareSummaryTitle => 'Trip completed';

  @override
  String get fareFinalPrice => 'Final price';

  @override
  String get fareEstimatedPrice => 'Estimated price';

  @override
  String get fareDifference => 'Difference';

  @override
  String get fareDistanceDriven => 'Distance driven';

  @override
  String get fareCommission => 'Commission';

  @override
  String get fareYourEarning => 'Your earnings';

  @override
  String get done => 'Done';

  @override
  String get driverReportArrival => 'I\'ve arrived';

  @override
  String get driverFinishTrip => 'Finish trip';

  @override
  String get walletFines => 'Administrative fines';

  @override
  String get walletNoFines => 'No fines';

  @override
  String get walletTotalCommissions => 'Total commissions';

  @override
  String get walletBonuses => 'Bonuses';

  @override
  String get walletCompletedTrips => 'Completed trips';

  @override
  String walletTripsCount(String count) {
    return '$count trips';
  }

  @override
  String get walletMonthlyIncome => 'Total income this month';

  @override
  String get txTopup => 'Top-up';

  @override
  String get txCommission => 'Commission';

  @override
  String get txPenalty => 'Penalty';

  @override
  String get txCompensation => 'Compensation';

  @override
  String get profileName => 'Name';

  @override
  String get profileRating => 'Rating';

  @override
  String get profileNoRatingYet => 'None yet';

  @override
  String get profileWalletBalance => 'Wallet balance';

  @override
  String get vehicleInfo => 'Vehicle details';

  @override
  String get vehicleType => 'Type';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehiclePlate => 'Plate number';

  @override
  String get editPersonalInfo => 'Edit personal info';

  @override
  String get profileSaved => 'Your details were saved successfully';

  @override
  String get errLoadData => 'Couldn\'t load the data';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get firstNameEditHint => 'Enter your first name';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyNameHint => 'Enter your family name';

  @override
  String get phoneEditHint => 'Enter your phone number';

  @override
  String get emailOptionalLabel => 'Email (optional)';

  @override
  String get addressOptionalLabel => 'Address (optional)';

  @override
  String get addressHint => 'City or neighborhood';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String greetingOnly(String greeting) {
    return '$greeting 👋';
  }

  @override
  String get homeRequestInProgress => 'Your request is in progress';

  @override
  String get homeWhereTo => 'Where do you want to go today?';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get pickPickupPoint => 'Choose pickup point';

  @override
  String get pickDestination => 'Choose your destination';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get search => 'Search';

  @override
  String get pickVehicleType => 'Choose vehicle type';

  @override
  String get priceEstimateNote =>
      'The price is an estimate and may differ with the actual route';

  @override
  String get notAvailableNow => 'Currently unavailable';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get searchPlaceHint => 'Search for a place...';

  @override
  String get mapLocationFallback => 'Location on the map';

  @override
  String get priceEstimateTag => '(estimated price)';

  @override
  String get rideAwaitingDriver => 'Waiting for a driver to accept';

  @override
  String get rideAccepted => 'Your request was accepted';

  @override
  String get rideDriverArrived => 'The driver has arrived';

  @override
  String get rideInProgress => 'Trip in progress';

  @override
  String get rideCompleted => 'Trip completed';

  @override
  String get rideRequestCancelled => 'Request cancelled';

  @override
  String get trackDriverOnTheWay => 'The driver is on the way to you';

  @override
  String get trackDriverAtPickup => 'The driver reached the pickup point';

  @override
  String get tripCompletedSuccess => 'Trip completed successfully';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyAgreePrefix => 'I agree to the ';

  @override
  String get privacyPolicyRequired =>
      'You need to accept the privacy policy to create an account';

  @override
  String get privacyPolicyEmpty =>
      'The privacy policy has not been published yet.';

  @override
  String get close => 'Close';

  @override
  String get payDriverTitle => 'Trip completed';

  @override
  String get payDriverMessage => 'Please pay the driver';

  @override
  String get payDriverWaiting =>
      'Waiting for the driver to confirm your payment';

  @override
  String get trackTrip => 'Track trip';

  @override
  String get safeTripTitle => 'Safe, verified trip';

  @override
  String get safeTripActive => 'Route tracking and location sharing are on';

  @override
  String get safeTripActivating => 'Safety features are being activated';

  @override
  String get connectionErrorRetrying => 'Couldn\'t reach the server — retrying';

  @override
  String get connecting => 'Connecting...';

  @override
  String get errLoginRequired => 'You must sign in';

  @override
  String get rideStatusPending => 'Pending';

  @override
  String get rideStatusAcceptedHist => 'Accepted';

  @override
  String get rideStatusArrivedHist => 'Driver arrived';

  @override
  String get rideStatusInProgressHist => 'In progress';

  @override
  String get rideStatusCompletedHist => 'Completed';

  @override
  String get rideStatusCancelledHist => 'Cancelled';

  @override
  String rideDetailsTitle(String id) {
    return 'Ride details #$id';
  }

  @override
  String get rideDrivenRouteTitle => 'Route driven';

  @override
  String get errLoadDetails => 'Couldn\'t load the details';

  @override
  String get cancelledByCustomer => 'Customer';

  @override
  String get cancelledByDriver => 'Driver';

  @override
  String get cancelledByManager => 'Management';

  @override
  String get detailRequestedAt => 'Requested on';

  @override
  String get detailAcceptedAt => 'Accepted at';

  @override
  String get detailStartedAt => 'Trip started';

  @override
  String get detailCompletedAt => 'Trip ended';

  @override
  String get detailCancelledAt => 'Cancelled at';

  @override
  String get detailCancelledBy => 'Cancelled by';

  @override
  String get detailDistance => 'Distance';

  @override
  String get detailEstimatedDuration => 'Estimated duration';

  @override
  String get detailStopsFee => 'Stop fees';

  @override
  String get noRidesYet => 'No rides yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get errPlacesSearch =>
      'Search is unavailable right now, please try again';

  @override
  String get locationResolving => 'Finding the address...';

  @override
  String get locationUnresolved =>
      'No address found for this spot. Move the pin and try again.';

  @override
  String get waitingAtPickup => 'Waiting at pickup';

  @override
  String waitingFreeLeft(String time) {
    return 'Free time left: $time';
  }

  @override
  String get waitingFreeOver => 'Free time is over';

  @override
  String waitingFeeFinal(String amount) {
    return 'Waiting fee: $amount';
  }

  @override
  String waitingRules(String minutes, String price) {
    return '$minutes free minutes, then $price per minute';
  }

  @override
  String get fareDistanceFare => 'Distance';

  @override
  String get fareBaseFare => 'Base fare';

  @override
  String get fareStopsFee => 'Stops';

  @override
  String get fareWaiting => 'Waiting';

  @override
  String fareWaitingDetail(String minutes, String price) {
    return '$minutes min × $price';
  }

  @override
  String get fareTotal => 'Total';

  @override
  String get pauseTripPaused => 'Trip paused';

  @override
  String pauseIncludedLeft(String time) {
    return 'Included time left: $time';
  }

  @override
  String get pauseIncludedOver => 'Included time is over';

  @override
  String pauseRules(String base, String minutes, String price) {
    return '$base includes $minutes minutes, then $price per minute';
  }

  @override
  String pauseFeeTotal(String amount) {
    return 'Pauses: $amount';
  }

  @override
  String get pauseStopLabel => 'Stop during the trip';

  @override
  String get driverPauseTrip => 'Pause trip';

  @override
  String get driverResumeTrip => 'Resume trip';

  @override
  String get farePauses => 'Pauses';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'This can\'t be undone. Your personal data, saved addresses and notifications will be erased and you\'ll be signed out on every device. Enter your password to confirm.';

  @override
  String get deleteAccountPasswordLabel => 'Password';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get deleteAccountDone => 'Your account has been deleted';

  @override
  String get errIncorrectPassword => 'Incorrect password';

  @override
  String get driverDeleteMessage =>
      'Your request will be reviewed by a manager. You can keep working until it\'s approved; then your personal data will be erased and you\'ll be signed out on every device. Enter your password to confirm.';

  @override
  String get driverDeleteReasonLabel => 'Reason (optional)';

  @override
  String get driverDeleteReasonHint => 'Why are you leaving?';

  @override
  String get driverDeleteSubmit => 'Send request';

  @override
  String get driverDeletionPendingTitle => 'Deletion request under review';

  @override
  String get driverDeletionPendingBody =>
      'A manager will review your request. You can keep working until it\'s approved.';

  @override
  String get driverDeletionCancel => 'Cancel request';

  @override
  String get driverDeletionRejectedTitle => 'Deletion request declined';

  @override
  String get errAccountDeleted => 'This account has been deleted';

  @override
  String get errDeleteActiveRide =>
      'You can\'t delete your account while a ride is in progress. Finish or cancel it first.';

  @override
  String get gpsRequiredTitle => 'Turn on location (GPS)';

  @override
  String get gpsRequiredMessage =>
      'The app can\'t be used while location is off. Turn on GPS to continue.';

  @override
  String get gpsOpenSettings => 'Open location settings';

  @override
  String get navRoute => 'Route';

  @override
  String get routeStartNew => 'Start a new route';

  @override
  String get routeSummaryTitle => 'Route summary';

  @override
  String get routeSummaryWaiting => 'Waiting at start';

  @override
  String get routeSummaryTripTime => 'Trip time';

  @override
  String get routeSummaryStops => 'Stops (coffee)';

  @override
  String get routeSummaryDriving => 'Driving time';

  @override
  String get routeLocationDenied =>
      'Location access is needed to record the route';

  @override
  String farePausesDetail(String count, String time) {
    return '×$count · $time';
  }

  @override
  String get accountBlockedTitle => 'Your account is temporarily blocked';

  @override
  String get accountBlockedRiderMessage =>
      'You can\'t request new rides while the block is active. A ride already in progress isn\'t affected.';

  @override
  String get accountBlockedDriverMessage =>
      'You won\'t receive new ride offers while the block is active. A trip already in progress isn\'t affected.';

  @override
  String accountBlockedUntil(String date) {
    return 'Blocked until $date';
  }

  @override
  String accountBlockedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get contactUs => 'Contact us';

  @override
  String get noContactNumbers => 'No contact numbers yet.';

  @override
  String get whatsappNotAvailable => 'WhatsApp isn\'t available on this device';

  @override
  String get callNotAvailable => 'Calls aren\'t supported on this device';

  @override
  String accountBlockedStrikes(int count, int limit) {
    return 'Cancellations: $count of $limit';
  }
}
