import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Smart Taxi'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Taxi — your ride, easy and safe'**
  String get appTagline;

  /// No description provided for @appVersionFooter.
  ///
  /// In en, this message translates to:
  /// **'Smart Taxi version {version} (2026)'**
  String appVersionFooter(String version);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @appUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateAction;

  /// No description provided for @appUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLater;

  /// No description provided for @appUpdateOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'A new update is available'**
  String get appUpdateOptionalTitle;

  /// No description provided for @appUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get appUpdateRequiredTitle;

  /// No description provided for @appUpdateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is no longer supported. Please update to continue.'**
  String get appUpdateRequiredMessage;

  /// No description provided for @appMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get appMaintenanceTitle;

  /// No description provided for @appMaintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re improving the app and will be back shortly.'**
  String get appMaintenanceMessage;

  /// No description provided for @appMaintenanceBackAt.
  ///
  /// In en, this message translates to:
  /// **'Back at {time}'**
  String appMaintenanceBackAt(String time);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get confirmCancellation;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navCreateRequest.
  ///
  /// In en, this message translates to:
  /// **'New ride'**
  String get navCreateRequest;

  /// No description provided for @navMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My rides'**
  String get navMyRequests;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @distanceKmToPickup.
  ///
  /// In en, this message translates to:
  /// **'{value} km to pickup'**
  String distanceKmToPickup(String value);

  /// No description provided for @durationMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutesShort(String minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(String minutes);

  /// No description provided for @priceSyp.
  ///
  /// In en, this message translates to:
  /// **'{amount} SYP'**
  String priceSyp(String amount);

  /// No description provided for @priceLyd.
  ///
  /// In en, this message translates to:
  /// **'{amount} LYD'**
  String priceLyd(String amount);

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDec;

  /// No description provided for @timeAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePm;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection to the server timed out'**
  String get errTimeout;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the internet, check your connection'**
  String get errNoInternet;

  /// No description provided for @errRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled'**
  String get errRequestCancelled;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errUnexpected;

  /// No description provided for @errServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the server'**
  String get errServerUnreachable;

  /// No description provided for @errNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the server'**
  String get errNotConnected;

  /// No description provided for @errInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request'**
  String get errInvalidRequest;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect phone number or password'**
  String get errWrongCredentials;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired, please sign in again'**
  String get errSessionExpired;

  /// No description provided for @errAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'You can\'t sign in, your account is not active right now'**
  String get errAccountInactive;

  /// No description provided for @errNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You aren\'t allowed to do this'**
  String get errNotAllowed;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item was not found'**
  String get errNotFound;

  /// No description provided for @errAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This account already exists'**
  String get errAccountExists;

  /// No description provided for @errActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This action can\'t be performed right now'**
  String get errActionUnavailable;

  /// No description provided for @errCheckInput.
  ///
  /// In en, this message translates to:
  /// **'Check the entered data'**
  String get errCheckInput;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred, try again later'**
  String get errServer;

  /// No description provided for @errCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Check: {fields}'**
  String errCheckFields(String fields);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @errCheckThisField.
  ///
  /// In en, this message translates to:
  /// **'Check this field'**
  String get errCheckThisField;

  /// No description provided for @errAccountNotForApp.
  ///
  /// In en, this message translates to:
  /// **'This account isn\'t meant for this app'**
  String get errAccountNotForApp;

  /// No description provided for @errServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The requested service is not available'**
  String get errServiceUnavailable;

  /// No description provided for @errAccountPending.
  ///
  /// In en, this message translates to:
  /// **'Your account is under review and will be activated once approved'**
  String get errAccountPending;

  /// No description provided for @errAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended, please contact support'**
  String get errAccountSuspended;

  /// No description provided for @errFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errFieldRequired;

  /// No description provided for @errPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get errPhoneRequired;

  /// No description provided for @errPhoneRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered'**
  String get errPhoneRegistered;

  /// No description provided for @errPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be between 8 and 64 characters'**
  String get errPasswordLength;

  /// No description provided for @errPasswordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one letter and one number'**
  String get errPasswordNeedsNumber;

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// No description provided for @fieldSession.
  ///
  /// In en, this message translates to:
  /// **'Login session'**
  String get fieldSession;

  /// No description provided for @fieldMessage.
  ///
  /// In en, this message translates to:
  /// **'Message text'**
  String get fieldMessage;

  /// No description provided for @fieldSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get fieldSubject;

  /// No description provided for @fieldVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get fieldVehicleType;

  /// No description provided for @fieldPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get fieldPickupLocation;

  /// No description provided for @fieldPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup address'**
  String get fieldPickupAddress;

  /// No description provided for @fieldDropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location'**
  String get fieldDropoffLocation;

  /// No description provided for @fieldDropoffAddress.
  ///
  /// In en, this message translates to:
  /// **'Drop-off address'**
  String get fieldDropoffAddress;

  /// No description provided for @fieldCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get fieldCancelReason;

  /// No description provided for @fieldSearchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get fieldSearchRadius;

  /// No description provided for @guidePassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8–64 characters, with no spaces, and include at least one letter and one number'**
  String get guidePassword;

  /// No description provided for @guideFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name must be between 2 and 100 characters'**
  String get guideFirstName;

  /// No description provided for @guideLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name must be between 2 and 100 characters'**
  String get guideLastName;

  /// No description provided for @guideMessage.
  ///
  /// In en, this message translates to:
  /// **'Message must be between 5 and 1000 characters'**
  String get guideMessage;

  /// No description provided for @guideSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject must not exceed 150 characters'**
  String get guideSubject;

  /// No description provided for @guideSearchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search radius must be between 0.1 and 100 km'**
  String get guideSearchRadius;

  /// No description provided for @guideCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason must not exceed 255 characters'**
  String get guideCancelReason;

  /// No description provided for @valPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get valPhone;

  /// No description provided for @valPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get valPasswordRequired;

  /// No description provided for @valPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters and contain a letter and a number'**
  String get valPasswordRule;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get valPasswordMismatch;

  /// No description provided for @valNameLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters only, at least 2 characters'**
  String get valNameLetters;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get valEmailInvalid;

  /// No description provided for @errLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on your device'**
  String get errLocationServiceOff;

  /// No description provided for @errLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get errLocationDenied;

  /// No description provided for @errEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Please turn on location services (GPS) in your device settings'**
  String get errEnableGps;

  /// No description provided for @errEnableLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please allow the app to use your location in your device settings'**
  String get errEnableLocationPermission;

  /// No description provided for @roleRider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get roleRider;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get roleDriver;

  /// No description provided for @roleRiderDescription.
  ///
  /// In en, this message translates to:
  /// **'Book your rides and get around easily and safely'**
  String get roleRiderDescription;

  /// No description provided for @roleDriverDescription.
  ///
  /// In en, this message translates to:
  /// **'Join as a driver and start receiving rides'**
  String get roleDriverDescription;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutConfirm;

  /// No description provided for @logoutFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Log out of account'**
  String get logoutFromAccount;

  /// No description provided for @logoutMessageDriver.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutMessageDriver;

  /// No description provided for @logoutMessageRider.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account? You\'ll need to sign in again to continue.'**
  String get logoutMessageRider;

  /// No description provided for @complaintSend.
  ///
  /// In en, this message translates to:
  /// **'Send a report'**
  String get complaintSend;

  /// No description provided for @complaintSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get complaintSubjectLabel;

  /// No description provided for @complaintSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'A short title for the report'**
  String get complaintSubjectHint;

  /// No description provided for @complaintDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get complaintDetailsLabel;

  /// No description provided for @complaintDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Write the report details here...'**
  String get complaintDetailsHint;

  /// No description provided for @complaintMinLength.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 5 characters'**
  String get complaintMinLength;

  /// No description provided for @complaintMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum 1000 characters'**
  String get complaintMaxLength;

  /// No description provided for @complaintSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report'**
  String get complaintSendFailed;

  /// No description provided for @complaintSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent successfully'**
  String get complaintSent;

  /// No description provided for @cancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// No description provided for @cancelTripReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please write the reason for cancelling the trip'**
  String get cancelTripReasonPrompt;

  /// No description provided for @cancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write the cancellation reason'**
  String get cancelReasonRequired;

  /// No description provided for @cancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Write the reason here...'**
  String get cancelReasonHint;

  /// No description provided for @tripCancelled.
  ///
  /// In en, this message translates to:
  /// **'The trip was cancelled'**
  String get tripCancelled;

  /// No description provided for @tripCancelledByCustomer.
  ///
  /// In en, this message translates to:
  /// **'The customer cancelled the trip'**
  String get tripCancelledByCustomer;

  /// No description provided for @tripCancelledByManager.
  ///
  /// In en, this message translates to:
  /// **'The trip was cancelled by the manager'**
  String get tripCancelledByManager;

  /// No description provided for @notificationsChannelName.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsChannelName;

  /// No description provided for @notificationsChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Ride updates, offers and alerts'**
  String get notificationsChannelDescription;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Taxi'**
  String get welcomeToApp;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type to continue'**
  String get chooseAccountType;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to continue to Smart Taxi'**
  String get signInSubtitle;

  /// No description provided for @driverSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Captain sign in'**
  String get driverSignInTitle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to create a new Smart Taxi account'**
  String get signUpSubtitle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccount;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mohammed'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alotaibi'**
  String get lastNameHint;

  /// No description provided for @driverStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get driverStatusPending;

  /// No description provided for @driverStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get driverStatusActive;

  /// No description provided for @driverStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get driverStatusSuspended;

  /// No description provided for @driverStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get driverStatusRejected;

  /// No description provided for @searchRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip search radius'**
  String get searchRadiusTitle;

  /// No description provided for @searchRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'The maximum distance for receiving nearby trip requests'**
  String get searchRadiusDescription;

  /// No description provided for @searchRadiusSaved.
  ///
  /// In en, this message translates to:
  /// **'Search radius saved'**
  String get searchRadiusSaved;

  /// No description provided for @searchRadiusSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the search radius'**
  String get searchRadiusSaveFailed;

  /// No description provided for @driverAcceptTrip.
  ///
  /// In en, this message translates to:
  /// **'Accept trip'**
  String get driverAcceptTrip;

  /// No description provided for @driverAcceptTripFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept the trip'**
  String get driverAcceptTripFailed;

  /// No description provided for @driverGoOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'Go online to see trip requests'**
  String get driverGoOnlineHint;

  /// No description provided for @driverWaitingForOrders.
  ///
  /// In en, this message translates to:
  /// **'Waiting for new trip requests...'**
  String get driverWaitingForOrders;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @driverAvailabilityPaused.
  ///
  /// In en, this message translates to:
  /// **'Going online is disabled until your account is activated'**
  String get driverAvailabilityPaused;

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Available for trips'**
  String get presenceOnline;

  /// No description provided for @presenceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get presenceConnecting;

  /// No description provided for @presenceOffline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get presenceOffline;

  /// No description provided for @locationSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re available for trips'**
  String get locationSharingTitle;

  /// No description provided for @locationSharingText.
  ///
  /// In en, this message translates to:
  /// **'Your location is shared with the dispatcher while you\'re available'**
  String get locationSharingText;

  /// No description provided for @locationSharingChannel.
  ///
  /// In en, this message translates to:
  /// **'Location sharing'**
  String get locationSharingChannel;

  /// No description provided for @driverGoToPickup.
  ///
  /// In en, this message translates to:
  /// **'Head to the pickup point'**
  String get driverGoToPickup;

  /// No description provided for @driverStartedTheTrip.
  ///
  /// In en, this message translates to:
  /// **'Start the trip'**
  String get driverStartedTheTrip;

  /// No description provided for @driverArrivalReported.
  ///
  /// In en, this message translates to:
  /// **'Arrival reported'**
  String get driverArrivalReported;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @paymentConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmedTitle;

  /// No description provided for @paymentTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get paymentTotalPaid;

  /// No description provided for @paymentYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get paymentYourShare;

  /// No description provided for @paymentCommissionDeducted.
  ///
  /// In en, this message translates to:
  /// **'Commission deducted from wallet'**
  String get paymentCommissionDeducted;

  /// No description provided for @paymentWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get paymentWalletBalance;

  /// No description provided for @fareSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get fareSummaryTitle;

  /// No description provided for @fareFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get fareFinalPrice;

  /// No description provided for @fareEstimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get fareEstimatedPrice;

  /// No description provided for @fareDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get fareDifference;

  /// No description provided for @fareDistanceDriven.
  ///
  /// In en, this message translates to:
  /// **'Distance driven'**
  String get fareDistanceDriven;

  /// No description provided for @fareCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get fareCommission;

  /// No description provided for @fareYourEarning.
  ///
  /// In en, this message translates to:
  /// **'Your earnings'**
  String get fareYourEarning;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @driverReportArrival.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get driverReportArrival;

  /// No description provided for @driverFinishTrip.
  ///
  /// In en, this message translates to:
  /// **'Finish trip'**
  String get driverFinishTrip;

  /// No description provided for @walletFines.
  ///
  /// In en, this message translates to:
  /// **'Administrative fines'**
  String get walletFines;

  /// No description provided for @walletNoFines.
  ///
  /// In en, this message translates to:
  /// **'No fines'**
  String get walletNoFines;

  /// No description provided for @walletTotalCommissions.
  ///
  /// In en, this message translates to:
  /// **'Total commissions'**
  String get walletTotalCommissions;

  /// No description provided for @walletBonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get walletBonuses;

  /// No description provided for @walletCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get walletCompletedTrips;

  /// No description provided for @walletTripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trips'**
  String walletTripsCount(String count);

  /// No description provided for @walletMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income this month'**
  String get walletMonthlyIncome;

  /// No description provided for @txTopup.
  ///
  /// In en, this message translates to:
  /// **'Top-up'**
  String get txTopup;

  /// No description provided for @txCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get txCommission;

  /// No description provided for @txPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get txPenalty;

  /// No description provided for @txCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get txCompensation;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get profileRating;

  /// No description provided for @profileNoRatingYet.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get profileNoRatingYet;

  /// No description provided for @profileWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get profileWalletBalance;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleInfo;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get vehicleType;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModel;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get vehicleColor;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get vehiclePlate;

  /// No description provided for @editPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit personal info'**
  String get editPersonalInfo;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your details were saved successfully'**
  String get profileSaved;

  /// No description provided for @errLoadData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the data'**
  String get errLoadData;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @firstNameEditHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameEditHint;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your family name'**
  String get familyNameHint;

  /// No description provided for @phoneEditHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneEditHint;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @addressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptionalLabel;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'City or neighborhood'**
  String get addressHint;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name} 👋'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @greetingOnly.
  ///
  /// In en, this message translates to:
  /// **'{greeting} 👋'**
  String greetingOnly(String greeting);

  /// No description provided for @homeRequestInProgress.
  ///
  /// In en, this message translates to:
  /// **'Your request is in progress'**
  String get homeRequestInProgress;

  /// No description provided for @homeWhereTo.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go today?'**
  String get homeWhereTo;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @pickPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup point'**
  String get pickPickupPoint;

  /// No description provided for @pickDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose your destination'**
  String get pickDestination;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @pickVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle type'**
  String get pickVehicleType;

  /// No description provided for @priceEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'The price is an estimate and may differ with the actual route'**
  String get priceEstimateNote;

  /// No description provided for @notAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get notAvailableNow;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place...'**
  String get searchPlaceHint;

  /// No description provided for @mapLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Location on the map'**
  String get mapLocationFallback;

  /// No description provided for @priceEstimateTag.
  ///
  /// In en, this message translates to:
  /// **'(estimated price)'**
  String get priceEstimateTag;

  /// No description provided for @rideAwaitingDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a driver to accept'**
  String get rideAwaitingDriver;

  /// No description provided for @rideAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your request was accepted'**
  String get rideAccepted;

  /// No description provided for @rideDriverArrived.
  ///
  /// In en, this message translates to:
  /// **'The driver has arrived'**
  String get rideDriverArrived;

  /// No description provided for @rideInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get rideInProgress;

  /// No description provided for @rideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get rideCompleted;

  /// No description provided for @rideRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get rideRequestCancelled;

  /// No description provided for @trackDriverOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'The driver is on the way to you'**
  String get trackDriverOnTheWay;

  /// No description provided for @trackDriverAtPickup.
  ///
  /// In en, this message translates to:
  /// **'The driver reached the pickup point'**
  String get trackDriverAtPickup;

  /// No description provided for @tripCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip completed successfully'**
  String get tripCompletedSuccess;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get privacyPolicyAgreePrefix;

  /// No description provided for @privacyPolicyRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to accept the privacy policy to create an account'**
  String get privacyPolicyRequired;

  /// No description provided for @privacyPolicyEmpty.
  ///
  /// In en, this message translates to:
  /// **'The privacy policy has not been published yet.'**
  String get privacyPolicyEmpty;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @payDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get payDriverTitle;

  /// No description provided for @payDriverMessage.
  ///
  /// In en, this message translates to:
  /// **'Please pay the driver'**
  String get payDriverMessage;

  /// No description provided for @payDriverWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to confirm your payment'**
  String get payDriverWaiting;

  /// No description provided for @trackTrip.
  ///
  /// In en, this message translates to:
  /// **'Track trip'**
  String get trackTrip;

  /// No description provided for @safeTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe, verified trip'**
  String get safeTripTitle;

  /// No description provided for @safeTripActive.
  ///
  /// In en, this message translates to:
  /// **'Route tracking and location sharing are on'**
  String get safeTripActive;

  /// No description provided for @safeTripActivating.
  ///
  /// In en, this message translates to:
  /// **'Safety features are being activated'**
  String get safeTripActivating;

  /// No description provided for @connectionErrorRetrying.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server — retrying'**
  String get connectionErrorRetrying;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @errLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must sign in'**
  String get errLoginRequired;

  /// No description provided for @rideStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get rideStatusPending;

  /// No description provided for @rideStatusAcceptedHist.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get rideStatusAcceptedHist;

  /// No description provided for @rideStatusArrivedHist.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived'**
  String get rideStatusArrivedHist;

  /// No description provided for @rideStatusInProgressHist.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get rideStatusInProgressHist;

  /// No description provided for @rideStatusCompletedHist.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get rideStatusCompletedHist;

  /// No description provided for @rideStatusCancelledHist.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get rideStatusCancelledHist;

  /// No description provided for @rideDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride details #{id}'**
  String rideDetailsTitle(String id);

  /// No description provided for @rideDrivenRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Route driven'**
  String get rideDrivenRouteTitle;

  /// No description provided for @errLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the details'**
  String get errLoadDetails;

  /// No description provided for @cancelledByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get cancelledByCustomer;

  /// No description provided for @cancelledByDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get cancelledByDriver;

  /// No description provided for @cancelledByManager.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get cancelledByManager;

  /// No description provided for @detailRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get detailRequestedAt;

  /// No description provided for @detailAcceptedAt.
  ///
  /// In en, this message translates to:
  /// **'Accepted at'**
  String get detailAcceptedAt;

  /// No description provided for @detailStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get detailStartedAt;

  /// No description provided for @detailCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get detailCompletedAt;

  /// No description provided for @detailCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get detailCancelledAt;

  /// No description provided for @detailCancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by'**
  String get detailCancelledBy;

  /// No description provided for @detailDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get detailDistance;

  /// No description provided for @detailEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get detailEstimatedDuration;

  /// No description provided for @detailStopsFee.
  ///
  /// In en, this message translates to:
  /// **'Stop fees'**
  String get detailStopsFee;

  /// No description provided for @noRidesYet.
  ///
  /// In en, this message translates to:
  /// **'No rides yet'**
  String get noRidesYet;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @errPlacesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search is unavailable right now, please try again'**
  String get errPlacesSearch;

  /// No description provided for @locationResolving.
  ///
  /// In en, this message translates to:
  /// **'Finding the address...'**
  String get locationResolving;

  /// No description provided for @locationUnresolved.
  ///
  /// In en, this message translates to:
  /// **'No address found for this spot. Move the pin and try again.'**
  String get locationUnresolved;

  /// No description provided for @waitingAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Waiting at pickup'**
  String get waitingAtPickup;

  /// No description provided for @waitingFreeLeft.
  ///
  /// In en, this message translates to:
  /// **'Free time left: {time}'**
  String waitingFreeLeft(String time);

  /// No description provided for @waitingFreeOver.
  ///
  /// In en, this message translates to:
  /// **'Free time is over'**
  String get waitingFreeOver;

  /// No description provided for @waitingFeeFinal.
  ///
  /// In en, this message translates to:
  /// **'Waiting fee: {amount}'**
  String waitingFeeFinal(String amount);

  /// No description provided for @waitingRules.
  ///
  /// In en, this message translates to:
  /// **'{minutes} free minutes, then {price} per minute'**
  String waitingRules(String minutes, String price);

  /// No description provided for @fareDistanceFare.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get fareDistanceFare;

  /// No description provided for @fareBaseFare.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get fareBaseFare;

  /// No description provided for @fareStopsFee.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get fareStopsFee;

  /// No description provided for @fareWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get fareWaiting;

  /// No description provided for @fareWaitingDetail.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min × {price}'**
  String fareWaitingDetail(String minutes, String price);

  /// No description provided for @fareTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get fareTotal;

  /// No description provided for @pauseTripPaused.
  ///
  /// In en, this message translates to:
  /// **'Trip paused'**
  String get pauseTripPaused;

  /// No description provided for @pauseIncludedLeft.
  ///
  /// In en, this message translates to:
  /// **'Included time left: {time}'**
  String pauseIncludedLeft(String time);

  /// No description provided for @pauseIncludedOver.
  ///
  /// In en, this message translates to:
  /// **'Included time is over'**
  String get pauseIncludedOver;

  /// No description provided for @pauseRules.
  ///
  /// In en, this message translates to:
  /// **'{base} includes {minutes} minutes, then {price} per minute'**
  String pauseRules(String base, String minutes, String price);

  /// No description provided for @pauseFeeTotal.
  ///
  /// In en, this message translates to:
  /// **'Pauses: {amount}'**
  String pauseFeeTotal(String amount);

  /// No description provided for @pauseStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop during the trip'**
  String get pauseStopLabel;

  /// No description provided for @driverPauseTrip.
  ///
  /// In en, this message translates to:
  /// **'Pause trip'**
  String get driverPauseTrip;

  /// No description provided for @driverResumeTrip.
  ///
  /// In en, this message translates to:
  /// **'Resume trip'**
  String get driverResumeTrip;

  /// No description provided for @farePauses.
  ///
  /// In en, this message translates to:
  /// **'Pauses'**
  String get farePauses;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Your personal data, saved addresses and notifications will be erased and you\'ll be signed out on every device. Enter your password to confirm.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get deleteAccountDone;

  /// No description provided for @errIncorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get errIncorrectPassword;

  /// No description provided for @driverDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request will be reviewed by a manager. You can keep working until it\'s approved; then your personal data will be erased and you\'ll be signed out on every device. Enter your password to confirm.'**
  String get driverDeleteMessage;

  /// No description provided for @driverDeleteReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get driverDeleteReasonLabel;

  /// No description provided for @driverDeleteReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get driverDeleteReasonHint;

  /// No description provided for @driverDeleteSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get driverDeleteSubmit;

  /// No description provided for @driverDeletionPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion request under review'**
  String get driverDeletionPendingTitle;

  /// No description provided for @driverDeletionPendingBody.
  ///
  /// In en, this message translates to:
  /// **'A manager will review your request. You can keep working until it\'s approved.'**
  String get driverDeletionPendingBody;

  /// No description provided for @driverDeletionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get driverDeletionCancel;

  /// No description provided for @driverDeletionRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion request declined'**
  String get driverDeletionRejectedTitle;

  /// No description provided for @errAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted'**
  String get errAccountDeleted;

  /// No description provided for @errDeleteActiveRide.
  ///
  /// In en, this message translates to:
  /// **'You can\'t delete your account while a ride is in progress. Finish or cancel it first.'**
  String get errDeleteActiveRide;

  /// No description provided for @gpsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS)'**
  String get gpsRequiredTitle;

  /// No description provided for @gpsRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'The app can\'t be used while location is off. Turn on GPS to continue.'**
  String get gpsRequiredMessage;

  /// No description provided for @gpsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get gpsOpenSettings;

  /// No description provided for @navRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get navRoute;

  /// No description provided for @routeStartNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new route'**
  String get routeStartNew;

  /// No description provided for @routeSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Route summary'**
  String get routeSummaryTitle;

  /// No description provided for @routeSummaryWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting at start'**
  String get routeSummaryWaiting;

  /// No description provided for @routeSummaryTripTime.
  ///
  /// In en, this message translates to:
  /// **'Trip time'**
  String get routeSummaryTripTime;

  /// No description provided for @routeSummaryStops.
  ///
  /// In en, this message translates to:
  /// **'Stops (coffee)'**
  String get routeSummaryStops;

  /// No description provided for @routeSummaryDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving time'**
  String get routeSummaryDriving;

  /// No description provided for @routeLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is needed to record the route'**
  String get routeLocationDenied;

  /// No description provided for @farePausesDetail.
  ///
  /// In en, this message translates to:
  /// **'×{count} · {time}'**
  String farePausesDetail(String count, String time);

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is temporarily blocked'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedRiderMessage.
  ///
  /// In en, this message translates to:
  /// **'You can\'t request new rides while the block is active. A ride already in progress isn\'t affected.'**
  String get accountBlockedRiderMessage;

  /// No description provided for @accountBlockedDriverMessage.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive new ride offers while the block is active. A trip already in progress isn\'t affected.'**
  String get accountBlockedDriverMessage;

  /// No description provided for @accountBlockedUntil.
  ///
  /// In en, this message translates to:
  /// **'Blocked until {date}'**
  String accountBlockedUntil(String date);

  /// No description provided for @accountBlockedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String accountBlockedReason(String reason);

  /// No description provided for @accountBlockedStrikes.
  ///
  /// In en, this message translates to:
  /// **'Cancellations: {count} of {limit}'**
  String accountBlockedStrikes(int count, int limit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
