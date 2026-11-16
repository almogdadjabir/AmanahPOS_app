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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get navSell;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navInventory;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navCashiers.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get navCashiers;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noData;

  /// No description provided for @settingsSectionManage.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get settingsSectionManage;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SECURITY'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get settingsSectionSupport;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize products'**
  String get settingsCategoriesSubtitle;

  /// No description provided for @settingsCashiers.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get settingsCashiers;

  /// No description provided for @settingsCashiersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff access & shifts'**
  String get settingsCashiersSubtitle;

  /// No description provided for @settingsCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get settingsCustomers;

  /// No description provided for @settingsCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles & loyalty'**
  String get settingsCustomersSubtitle;

  /// No description provided for @settingsReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get settingsReturns;

  /// No description provided for @settingsReturnsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Process customer item returns'**
  String get settingsReturnsSubtitle;

  /// No description provided for @settingsSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get settingsSalesHistory;

  /// No description provided for @settingsSalesHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and search all transactions'**
  String get settingsSalesHistorySubtitle;

  /// No description provided for @settingsSectionDevices.
  ///
  /// In en, this message translates to:
  /// **'DEVICES'**
  String get settingsSectionDevices;

  /// No description provided for @settingsAddPrinter.
  ///
  /// In en, this message translates to:
  /// **'Add Printer'**
  String get settingsAddPrinter;

  /// No description provided for @settingsPrinterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth receipt printer'**
  String get settingsPrinterSubtitle;

  /// No description provided for @printerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get printerScreenTitle;

  /// No description provided for @printerDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default printer'**
  String get printerDefaultLabel;

  /// No description provided for @printerStatusNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get printerStatusNotConnected;

  /// No description provided for @printerStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get printerStatusConnecting;

  /// No description provided for @printerStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get printerStatusConnected;

  /// No description provided for @printerStatusConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get printerStatusConnectionFailed;

  /// No description provided for @printerStatusPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printerStatusPrinting;

  /// No description provided for @printerStatusPrintSuccess.
  ///
  /// In en, this message translates to:
  /// **'Printed successfully'**
  String get printerStatusPrintSuccess;

  /// No description provided for @printerStatusPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed'**
  String get printerStatusPrintFailed;

  /// No description provided for @printerConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get printerConnect;

  /// No description provided for @printerDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get printerDisconnect;

  /// No description provided for @printerTestPrint.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get printerTestPrint;

  /// No description provided for @printerForget.
  ///
  /// In en, this message translates to:
  /// **'Remove printer'**
  String get printerForget;

  /// No description provided for @printerForgetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this printer?'**
  String get printerForgetConfirmTitle;

  /// No description provided for @printerForgetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can add it again at any time.'**
  String get printerForgetConfirmBody;

  /// No description provided for @printerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available printers'**
  String get printerAvailable;

  /// No description provided for @printerScan.
  ///
  /// In en, this message translates to:
  /// **'Scan for printers'**
  String get printerScan;

  /// No description provided for @printerScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get printerScanning;

  /// No description provided for @printerNoDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No printers found'**
  String get printerNoDevicesFound;

  /// No description provided for @printerScanHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the printer is turned on. On Android and Windows, pair it first in the system Bluetooth settings.'**
  String get printerScanHint;

  /// No description provided for @printerSavedAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Saved as default printer'**
  String get printerSavedAsDefault;

  /// No description provided for @printerErrorBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on and try again.'**
  String get printerErrorBluetoothOff;

  /// No description provided for @printerErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission denied. Allow Bluetooth access in app settings.'**
  String get printerErrorPermissionDenied;

  /// No description provided for @printerErrorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the printer. Check that it is turned on and in range.'**
  String get printerErrorConnectionFailed;

  /// No description provided for @printerErrorPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Printing failed. Check the printer and try again.'**
  String get printerErrorPrintFailed;

  /// No description provided for @printerErrorNoPrinterSaved.
  ///
  /// In en, this message translates to:
  /// **'No printer set up. Add a printer in Settings.'**
  String get printerErrorNoPrinterSaved;

  /// No description provided for @printerErrorScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not search for printers. Try again.'**
  String get printerErrorScanFailed;

  /// No description provided for @printerNetworkSection.
  ///
  /// In en, this message translates to:
  /// **'Network printer (LAN/WiFi)'**
  String get printerNetworkSection;

  /// No description provided for @printerAddNetwork.
  ///
  /// In en, this message translates to:
  /// **'Add network printer'**
  String get printerAddNetwork;

  /// No description provided for @printerIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get printerIpAddress;

  /// No description provided for @printerPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get printerPort;

  /// No description provided for @printerNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get printerNameOptional;

  /// No description provided for @printerInvalidIp.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address.'**
  String get printerInvalidIp;

  /// No description provided for @printerNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'For printers connected with a LAN cable or WiFi, like the SAM4s GIANT-100. To find the printer\'s IP address, hold the FEED button while turning the printer on - it prints a self-test page showing the IP.'**
  String get printerNetworkHint;

  /// No description provided for @printerBleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE'**
  String get printerBleLabel;

  /// No description provided for @printerNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'LAN/WiFi printer'**
  String get printerNetworkLabel;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get printReceipt;

  /// No description provided for @printerSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up printer'**
  String get printerSetUp;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsBankakPayments.
  ///
  /// In en, this message translates to:
  /// **'Bankak Payments'**
  String get settingsBankakPayments;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your account password'**
  String get settingsPasswordSubtitle;

  /// No description provided for @settingsWhatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support'**
  String get settingsWhatsappSupport;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @currentLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get currentLanguageName;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// No description provided for @languagePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language.'**
  String get languagePickerSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageEnglishNative.
  ///
  /// In en, this message translates to:
  /// **'English (EN)'**
  String get languageEnglishNative;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageArabicNative.
  ///
  /// In en, this message translates to:
  /// **'العربية (AR)'**
  String get languageArabicNative;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get profileUpdateFailed;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get passwordUpdateFailed;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutConfirmMessage;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsAnimations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get settingsAnimations;

  /// No description provided for @settingsAnimationsAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off on low-memory devices'**
  String get settingsAnimationsAutoSubtitle;

  /// No description provided for @animationsAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get animationsAuto;

  /// No description provided for @animationsAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get animationsAlwaysOn;

  /// No description provided for @animationsAlwaysOff.
  ///
  /// In en, this message translates to:
  /// **'Always off'**
  String get animationsAlwaysOff;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to receive a 6-digit verification code.'**
  String get loginSubtitle;

  /// No description provided for @loginMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get loginMobileLabel;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get loginTermsPrefix;

  /// No description provided for @loginTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get loginTermsLink;

  /// No description provided for @loginTermsSeparator.
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get loginTermsSeparator;

  /// No description provided for @loginPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get loginPrivacyLink;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpTitle;

  /// No description provided for @otpSentPrefix.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n'**
  String get otpSentPrefix;

  /// No description provided for @otpChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get otpChange;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in '**
  String get otpResendIn;

  /// No description provided for @otpResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendButton;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get otpVerifyButton;

  /// No description provided for @otpVerifiedButton.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get otpVerifiedButton;

  /// No description provided for @otpVerifiedSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Verified — signing you in…'**
  String get otpVerifiedSigningIn;

  /// No description provided for @themePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themePickerTitle;

  /// No description provided for @themePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how AmanaPOS looks on your device.'**
  String get themePickerSubtitle;

  /// No description provided for @themeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean bright interface. Always on.'**
  String get themeLightSubtitle;

  /// No description provided for @themeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes in low light.'**
  String get themeDarkSubtitle;

  /// No description provided for @themeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follows your device setting automatically.'**
  String get themeSystemSubtitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name and contact information.'**
  String get editProfileSubtitle;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fieldFullName;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPasswordTitle;

  /// No description provided for @setPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password to protect your AmanaPOS account.'**
  String get setPasswordSubtitle;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get fieldConfirmPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @bankakAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Bankak Account'**
  String get bankakAddTitle;

  /// No description provided for @bankakChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Bankak Account'**
  String get bankakChangeTitle;

  /// No description provided for @bankakSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used when cashier selects Bankak as payment method in POS.'**
  String get bankakSheetSubtitle;

  /// No description provided for @bankakInfoNote.
  ///
  /// In en, this message translates to:
  /// **'AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.'**
  String get bankakInfoNote;

  /// No description provided for @bankakAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bankak Account Number'**
  String get bankakAccountNumber;

  /// No description provided for @bankakSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get bankakSaveChanges;

  /// No description provided for @bankakAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get bankakAddAccount;

  /// No description provided for @bankakRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bankakRemove;

  /// No description provided for @bankakActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bankakActive;

  /// No description provided for @bankakNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get bankakNotSet;

  /// No description provided for @bankakUsedForLabel.
  ///
  /// In en, this message translates to:
  /// **'Used for Bankak sales tracking and reports.'**
  String get bankakUsedForLabel;

  /// No description provided for @bankakPosNote.
  ///
  /// In en, this message translates to:
  /// **'When cashier chooses Bankak in POS, AmanaPOS records the sale under this account.'**
  String get bankakPosNote;

  /// No description provided for @bankakCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Bankak Payments'**
  String get bankakCardTitle;

  /// No description provided for @bankakChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change Bankak Account'**
  String get bankakChangeButton;

  /// No description provided for @bankakAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Bankak Account'**
  String get bankakAddButton;

  /// No description provided for @bankakReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to accept Bankak sales'**
  String get bankakReadyTitle;

  /// No description provided for @bankakReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept Bankak payments in POS'**
  String get bankakReadySubtitle;

  /// No description provided for @bankakAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Account '**
  String get bankakAccountPrefix;

  /// No description provided for @bankakNoAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'No Bankak account added yet'**
  String get bankakNoAccountAdded;

  /// No description provided for @bankakUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Bankak Account'**
  String get bankakUpdateTitle;

  /// No description provided for @posTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today sales'**
  String get posTodaySales;

  /// No description provided for @posAllCategory.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posAllCategory;

  /// No description provided for @posSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search · SKU · Barcode'**
  String get posSearchHint;

  /// No description provided for @posBankakNotSetup.
  ///
  /// In en, this message translates to:
  /// **'Bankak account is not set up. Go to Settings and add your account number first.'**
  String get posBankakNotSetup;

  /// No description provided for @posCashierNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to a shop. Contact your manager.'**
  String get posCashierNotAssigned;

  /// No description provided for @posCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get posCharge;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @itemRemovedUndo.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String itemRemovedUndo(String name);

  /// No description provided for @posNoShopFound.
  ///
  /// In en, this message translates to:
  /// **'No shop found. Please refresh and try again.'**
  String get posNoShopFound;

  /// No description provided for @posSaleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale completed successfully'**
  String get posSaleCompleted;

  /// No description provided for @posFailedSale.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete sale'**
  String get posFailedSale;

  /// No description provided for @posBankakRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add your Bankak account number in Settings.'**
  String get posBankakRequired;

  /// No description provided for @posShopMismatch.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to this shop. Contact your manager.'**
  String get posShopMismatch;

  /// No description provided for @productsManagement.
  ///
  /// In en, this message translates to:
  /// **'Products Management'**
  String get productsManagement;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start building your catalog and begin selling.'**
  String get noProductsMessage;

  /// No description provided for @productStatAll.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productStatAll;

  /// No description provided for @productStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productStatActive;

  /// No description provided for @productStatOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get productStatOutOfStock;

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'Show list'**
  String get showList;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show grid'**
  String get showGrid;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @addProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add product photo'**
  String get addProductPhoto;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change product image'**
  String get tapToChangePhoto;

  /// No description provided for @fieldProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get fieldProductName;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fieldPrice;

  /// No description provided for @fieldCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get fieldCostPrice;

  /// No description provided for @fieldSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get fieldSku;

  /// No description provided for @fieldBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get fieldBarcode;

  /// No description provided for @fieldMinStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock Level'**
  String get fieldMinStockLevel;

  /// No description provided for @fieldExpiryAlertDays.
  ///
  /// In en, this message translates to:
  /// **'Expiry Alert (days)'**
  String get fieldExpiryAlertDays;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @stockByShop.
  ///
  /// In en, this message translates to:
  /// **'Stock by Shop'**
  String get stockByShop;

  /// No description provided for @productPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to change product image'**
  String get productPhotoSubtitle;

  /// No description provided for @inventoryAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Alerts'**
  String get inventoryAlertsTitle;

  /// No description provided for @inventoryAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set when AmanaPOS should warn you about low stock or expiring batches.'**
  String get inventoryAlertsSubtitle;

  /// No description provided for @inventoryAlertsExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'You will be notified when a product batch is within the set number of days from its expiry date.'**
  String get inventoryAlertsExpiryHint;

  /// No description provided for @fieldExpiryAlert.
  ///
  /// In en, this message translates to:
  /// **'Expiry Alert'**
  String get fieldExpiryAlert;

  /// No description provided for @menuCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Catalog'**
  String get menuCatalogTitle;

  /// No description provided for @productCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productCatalogTitle;

  /// No description provided for @menuCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage menu items, prices, and categories.'**
  String get menuCatalogSubtitle;

  /// No description provided for @productCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage items, prices, categories, and stock availability.'**
  String get productCatalogSubtitle;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @fieldCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get fieldCategoryName;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @catStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get catStatTotal;

  /// No description provided for @catStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get catStatActive;

  /// No description provided for @catStatInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get catStatInactive;

  /// No description provided for @catStatSub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get catStatSub;

  /// No description provided for @catAppBarProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get catAppBarProducts;

  /// No description provided for @catAppBarSub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get catAppBarSub;

  /// No description provided for @catAppBarStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get catAppBarStatus;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @expiredBatchOne.
  ///
  /// In en, this message translates to:
  /// **'1 batch expired'**
  String get expiredBatchOne;

  /// No description provided for @expiredBatchMany.
  ///
  /// In en, this message translates to:
  /// **'{count} batches expired'**
  String expiredBatchMany(int count);

  /// No description provided for @expiringSoonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring soon'**
  String expiringSoonCount(Object count);

  /// No description provided for @expiringSoonMany.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring soon'**
  String expiringSoonMany(Object count);

  /// No description provided for @expiringSoonBatchMany.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring soon'**
  String expiringSoonBatchMany(int count);

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// No description provided for @manyDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String manyDays(int count);

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get productAddedSuccessfully;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'Pepsi 330ml'**
  String get productNameHint;

  /// No description provided for @productDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Product description'**
  String get productDescriptionHint;

  /// No description provided for @generalCategory.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalCategory;

  /// No description provided for @autoCreated.
  ///
  /// In en, this message translates to:
  /// **'Auto-created'**
  String get autoCreated;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get selectBranch;

  /// No description provided for @businessWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Business workspace'**
  String get businessWorkspace;

  /// No description provided for @productDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeletedSuccessfully;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteProductMessage(String name);

  /// No description provided for @thisProduct.
  ///
  /// In en, this message translates to:
  /// **'this product'**
  String get thisProduct;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @productCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Categories'**
  String get productCategoriesTitle;

  /// No description provided for @productCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group products into simple sections for faster checkout and cleaner inventory.'**
  String get productCategoriesSubtitle;

  /// No description provided for @activeCategories.
  ///
  /// In en, this message translates to:
  /// **'Active Categories'**
  String get activeCategories;

  /// No description provided for @inactiveCategories.
  ///
  /// In en, this message translates to:
  /// **'Inactive Categories'**
  String get inactiveCategories;

  /// No description provided for @categoriesWithSubCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories With Sub Categories'**
  String get categoriesWithSubCategories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameRequired;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @invalidProduct.
  ///
  /// In en, this message translates to:
  /// **'Invalid product'**
  String get invalidProduct;

  /// No description provided for @categoryMissing.
  ///
  /// In en, this message translates to:
  /// **'Category is missing'**
  String get categoryMissing;

  /// No description provided for @productUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdatedSuccessfully;

  /// No description provided for @productPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productPhoto;

  /// No description provided for @tapToChangeProductImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to change product image'**
  String get tapToChangeProductImage;

  /// No description provided for @categoryLocked.
  ///
  /// In en, this message translates to:
  /// **'Category locked'**
  String get categoryLocked;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @noCategoriesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first category to organize products.'**
  String get noCategoriesYetMessage;

  /// No description provided for @noActiveCategories.
  ///
  /// In en, this message translates to:
  /// **'No active categories'**
  String get noActiveCategories;

  /// No description provided for @noActiveCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'No categories are currently active.'**
  String get noActiveCategoriesMessage;

  /// No description provided for @noInactiveCategories.
  ///
  /// In en, this message translates to:
  /// **'No inactive categories'**
  String get noInactiveCategories;

  /// No description provided for @noInactiveCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'All categories are currently active.'**
  String get noInactiveCategoriesMessage;

  /// No description provided for @noSubCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No sub categories found'**
  String get noSubCategoriesFound;

  /// No description provided for @noSubCategoriesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No categories have sub categories yet.'**
  String get noSubCategoriesFoundMessage;

  /// No description provided for @noDescriptionAdded.
  ///
  /// In en, this message translates to:
  /// **'No description added'**
  String get noDescriptionAdded;

  /// No description provided for @subCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sub'**
  String subCategoryCount(int count);

  /// No description provided for @categoryCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category created successfully'**
  String get categoryCreatedSuccessfully;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryNameHint;

  /// No description provided for @categoryDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Drinks, juices, water, and hot beverages'**
  String get categoryDescriptionHint;

  /// No description provided for @createProductGroup.
  ///
  /// In en, this message translates to:
  /// **'Create product group'**
  String get createProductGroup;

  /// No description provided for @createProductGroupMessage.
  ///
  /// In en, this message translates to:
  /// **'Use categories to organize products and speed up checkout.'**
  String get createProductGroupMessage;

  /// No description provided for @categoryTipsMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep category names short and clear, like Snacks, Drinks, Groceries, or Meals.'**
  String get categoryTipsMessage;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// No description provided for @categoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully'**
  String get categoryUpdatedSuccessfully;

  /// No description provided for @invalidCategory.
  ///
  /// In en, this message translates to:
  /// **'Invalid category'**
  String get invalidCategory;

  /// No description provided for @categoryDescriptionShortHint.
  ///
  /// In en, this message translates to:
  /// **'Drinks and beverages'**
  String get categoryDescriptionShortHint;

  /// No description provided for @categoryDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize products under this category for faster POS usage.'**
  String get categoryDefaultDescription;

  /// No description provided for @categoryNoProductsMessage.
  ///
  /// In en, this message translates to:
  /// **'This category is ready. Add the first product here so it appears directly under this category.'**
  String get categoryNoProductsMessage;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @productCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productCountLabel(int count);

  /// No description provided for @categoryDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully'**
  String get categoryDeletedSuccessfully;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently deleted. This action cannot be undone.'**
  String deleteCategoryMessage(String name);

  /// No description provided for @addCashier.
  ///
  /// In en, this message translates to:
  /// **'Add Cashier'**
  String get addCashier;

  /// No description provided for @userStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get userStatTotal;

  /// No description provided for @userStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userStatActive;

  /// No description provided for @userStatCashiers.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get userStatCashiers;

  /// No description provided for @userStatManagers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get userStatManagers;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @createStaffAccount.
  ///
  /// In en, this message translates to:
  /// **'Create staff account'**
  String get createStaffAccount;

  /// No description provided for @editStaffAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit staff account'**
  String get editStaffAccount;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhone;

  /// No description provided for @fieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get fieldRole;

  /// No description provided for @fieldAssignedShop.
  ///
  /// In en, this message translates to:
  /// **'Assigned Shop'**
  String get fieldAssignedShop;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @userInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get userInfoTitle;

  /// No description provided for @userInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic cashier profile and access status.'**
  String get userInfoSubtitle;

  /// No description provided for @userActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get userActivityTitle;

  /// No description provided for @userActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login and account creation details.'**
  String get userActivitySubtitle;

  /// No description provided for @userDetailPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get userDetailPhone;

  /// No description provided for @userDetailRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userDetailRole;

  /// No description provided for @userDetailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get userDetailVerified;

  /// No description provided for @userDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get userDetailStatus;

  /// No description provided for @userDetailLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get userDetailLastLogin;

  /// No description provided for @userDetailJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get userDetailJoined;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User?'**
  String get deactivateUser;

  /// No description provided for @managerAccess.
  ///
  /// In en, this message translates to:
  /// **'Manager access'**
  String get managerAccess;

  /// No description provided for @shopRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop required'**
  String get shopRequired;

  /// No description provided for @shopAssigned.
  ///
  /// In en, this message translates to:
  /// **'Shop assigned'**
  String get shopAssigned;

  /// No description provided for @unassignedCashier.
  ///
  /// In en, this message translates to:
  /// **'Unassigned cashier'**
  String get unassignedCashier;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @customerStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get customerStatTotal;

  /// No description provided for @customerStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customerStatActive;

  /// No description provided for @customerStatInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customerStatInactive;

  /// No description provided for @customerStatCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get customerStatCredit;

  /// No description provided for @customerStatPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerStatPhone;

  /// No description provided for @fieldCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get fieldCustomerName;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldLoyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get fieldLoyaltyPoints;

  /// No description provided for @createCustomer.
  ///
  /// In en, this message translates to:
  /// **'Create Customer'**
  String get createCustomer;

  /// No description provided for @customerInactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customerInactiveLabel;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers, phone, email...'**
  String get customerSearchHint;

  /// No description provided for @customerSalesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get customerSalesPrefix;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @cashiers.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get cashiers;

  /// No description provided for @managers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get managers;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @usersManagement.
  ///
  /// In en, this message translates to:
  /// **'Users Management'**
  String get usersManagement;

  /// No description provided for @usersManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage staff accounts, roles, shop access, and POS permissions.'**
  String get usersManagementSubtitle;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get noUsersYet;

  /// No description provided for @noUsersYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first user so your team can start using the POS.'**
  String get noUsersYetMessage;

  /// No description provided for @noActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'No active users'**
  String get noActiveUsers;

  /// No description provided for @noActiveUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'No users are currently active.'**
  String get noActiveUsersMessage;

  /// No description provided for @noCashiersFound.
  ///
  /// In en, this message translates to:
  /// **'No cashiers found'**
  String get noCashiersFound;

  /// No description provided for @noCashiersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No cashier accounts are currently available.'**
  String get noCashiersFoundMessage;

  /// No description provided for @noManagersFound.
  ///
  /// In en, this message translates to:
  /// **'No managers found'**
  String get noManagersFound;

  /// No description provided for @noManagersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No manager accounts are currently available.'**
  String get noManagersFoundMessage;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage customer profiles, phone numbers, loyalty, and purchase history.'**
  String get customersSubtitle;

  /// No description provided for @customerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdatedSuccess;

  /// No description provided for @customerUpdatedShort.
  ///
  /// In en, this message translates to:
  /// **'Customer updated'**
  String get customerUpdatedShort;

  /// No description provided for @customerCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created'**
  String get customerCreated;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @customersNotFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersNotFound;

  /// No description provided for @customersEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmptyAll;

  /// No description provided for @customersEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active customers'**
  String get customersEmptyActive;

  /// No description provided for @customersEmptyInactive.
  ///
  /// In en, this message translates to:
  /// **'No inactive customers'**
  String get customersEmptyInactive;

  /// No description provided for @customersEmptyCredit.
  ///
  /// In en, this message translates to:
  /// **'No credit customers'**
  String get customersEmptyCredit;

  /// No description provided for @customersEmptyPhone.
  ///
  /// In en, this message translates to:
  /// **'No customers with phone'**
  String get customersEmptyPhone;

  /// No description provided for @customersEmptyAllMsg.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to track loyalty and purchases.'**
  String get customersEmptyAllMsg;

  /// No description provided for @customersEmptyActiveMsg.
  ///
  /// In en, this message translates to:
  /// **'No customers are currently active.'**
  String get customersEmptyActiveMsg;

  /// No description provided for @customersEmptyInactiveMsg.
  ///
  /// In en, this message translates to:
  /// **'All customers are currently active.'**
  String get customersEmptyInactiveMsg;

  /// No description provided for @customersEmptyCreditMsg.
  ///
  /// In en, this message translates to:
  /// **'No customers currently have credit or purchase balance.'**
  String get customersEmptyCreditMsg;

  /// No description provided for @customersEmptyPhoneMsg.
  ///
  /// In en, this message translates to:
  /// **'No customers have phone numbers yet.'**
  String get customersEmptyPhoneMsg;

  /// No description provided for @customersNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customersNoMatchTitle;

  /// No description provided for @customersNoMatchMsg.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String customersNoMatchMsg(String query);

  /// No description provided for @customersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get customersLoadFailed;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @editCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update customer details and loyalty points.'**
  String get editCustomerSubtitle;

  /// No description provided for @addCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a customer profile for sales and loyalty.'**
  String get addCustomerSubtitle;

  /// No description provided for @hintCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Customer address'**
  String get hintCustomerAddress;

  /// No description provided for @hintCustomerNotes.
  ///
  /// In en, this message translates to:
  /// **'Any customer notes'**
  String get hintCustomerNotes;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer?'**
  String get deleteCustomerTitle;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteCustomerConfirm(String name);

  /// No description provided for @invalidCustomer.
  ///
  /// In en, this message translates to:
  /// **'Invalid customer'**
  String get invalidCustomer;

  /// No description provided for @loyaltyPointsSuffix.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String loyaltyPointsSuffix(int points);

  /// No description provided for @returnFindSale.
  ///
  /// In en, this message translates to:
  /// **'Find a sale to return'**
  String get returnFindSale;

  /// No description provided for @returnFindSaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a receipt number or amount above'**
  String get returnFindSaleSubtitle;

  /// No description provided for @returnSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get returnSearchFailed;

  /// No description provided for @returnNoSalesFound.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get returnNoSalesFound;

  /// No description provided for @returnNoSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different receipt number or amount'**
  String get returnNoSalesSubtitle;

  /// No description provided for @returnAll.
  ///
  /// In en, this message translates to:
  /// **'Return all'**
  String get returnAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @refCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get refCopied;

  /// No description provided for @shareReturnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share return receipt via WhatsApp'**
  String get shareReturnWhatsApp;

  /// No description provided for @salesHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get salesHistoryTitle;

  /// No description provided for @allSalesLoaded.
  ///
  /// In en, this message translates to:
  /// **'All sales loaded'**
  String get allSalesLoaded;

  /// No description provided for @saleReceiptFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate receipt PDF'**
  String get saleReceiptFailure;

  /// No description provided for @returnItemsAction.
  ///
  /// In en, this message translates to:
  /// **'Return items from this sale'**
  String get returnItemsAction;

  /// No description provided for @salesCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load sales'**
  String get salesCouldNotLoad;

  /// No description provided for @saleComplete.
  ///
  /// In en, this message translates to:
  /// **'Sale complete!'**
  String get saleComplete;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline'**
  String get savedOffline;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via...'**
  String get shareVia;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @receiptCopied.
  ///
  /// In en, this message translates to:
  /// **'Receipt number copied'**
  String get receiptCopied;

  /// No description provided for @saleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search receipt, amount, payment...'**
  String get saleSearchHint;

  /// No description provided for @amanaPosLabel.
  ///
  /// In en, this message translates to:
  /// **'AMANAPOS'**
  String get amanaPosLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @posStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get posStatusOffline;

  /// No description provided for @posStatusSyncIssue.
  ///
  /// In en, this message translates to:
  /// **'Sync issue'**
  String get posStatusSyncIssue;

  /// No description provided for @posStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posStatusPending;

  /// No description provided for @posStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get posStatusSyncing;

  /// No description provided for @posStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get posStatusSynced;

  /// No description provided for @clearLocalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data?'**
  String get clearLocalDataTitle;

  /// No description provided for @localDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared.'**
  String get localDataCleared;

  /// No description provided for @salesChipLabel.
  ///
  /// In en, this message translates to:
  /// **'SALES'**
  String get salesChipLabel;

  /// No description provided for @avgChipLabel.
  ///
  /// In en, this message translates to:
  /// **'AVG'**
  String get avgChipLabel;

  /// No description provided for @viewPendingCount.
  ///
  /// In en, this message translates to:
  /// **'View {count} pending'**
  String viewPendingCount(int count);

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more'**
  String get loadingMore;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @invExpiryExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invExpiryExpired;

  /// No description provided for @invExpiryExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get invExpiryExpiringSoon;

  /// No description provided for @invHeroExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get invHeroExport;

  /// No description provided for @invHeroScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get invHeroScan;

  /// No description provided for @invInventoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Inventory Health'**
  String get invInventoryHealth;

  /// No description provided for @invNeedsRestock.
  ///
  /// In en, this message translates to:
  /// **'Needs Restock'**
  String get invNeedsRestock;

  /// No description provided for @invInboundThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Inbound This Month'**
  String get invInboundThisMonth;

  /// No description provided for @invExpiringDays.
  ///
  /// In en, this message translates to:
  /// **'Expiring ≤30 days'**
  String get invExpiringDays;

  /// No description provided for @invQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get invQuickActionsTitle;

  /// No description provided for @invReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get invReceive;

  /// No description provided for @invStockAction.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get invStockAction;

  /// No description provided for @invVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get invVendors;

  /// No description provided for @invExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get invExpiry;

  /// No description provided for @invHealthRingTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Ring'**
  String get invHealthRingTitle;

  /// No description provided for @invHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get invHealthy;

  /// No description provided for @invLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get invLow;

  /// No description provided for @invOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get invOut;

  /// No description provided for @invInboundVelocityTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbound Velocity'**
  String get invInboundVelocityTitle;

  /// No description provided for @invExpiryTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiry Timeline'**
  String get invExpiryTimelineTitle;

  /// No description provided for @invRecentReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Receipts'**
  String get invRecentReceiptsTitle;

  /// No description provided for @invVendorBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendor Board'**
  String get invVendorBoardTitle;

  /// No description provided for @invRestockQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Restock Queue'**
  String get invRestockQueueTitle;

  /// No description provided for @invVendorSaved.
  ///
  /// In en, this message translates to:
  /// **'Vendor saved'**
  String get invVendorSaved;

  /// No description provided for @invVendorFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vendor'**
  String get invVendorFailed;

  /// No description provided for @invAddFirstVendor.
  ///
  /// In en, this message translates to:
  /// **'Add your first vendor'**
  String get invAddFirstVendor;

  /// No description provided for @invSelectVendor.
  ///
  /// In en, this message translates to:
  /// **'Select vendor'**
  String get invSelectVendor;

  /// No description provided for @invAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get invAddRow;

  /// No description provided for @invMovementType.
  ///
  /// In en, this message translates to:
  /// **'Movement Type'**
  String get invMovementType;

  /// No description provided for @invFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get invFieldQuantity;

  /// No description provided for @invFieldReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get invFieldReference;

  /// No description provided for @invConfirmMovement.
  ///
  /// In en, this message translates to:
  /// **'Confirm Movement'**
  String get invConfirmMovement;

  /// No description provided for @invFieldNewQuantity.
  ///
  /// In en, this message translates to:
  /// **'New Quantity'**
  String get invFieldNewQuantity;

  /// No description provided for @invFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get invFieldNotes;

  /// No description provided for @invAdjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock'**
  String get invAdjustStock;

  /// No description provided for @invTransferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer To'**
  String get invTransferTo;

  /// No description provided for @invQtyToTransfer.
  ///
  /// In en, this message translates to:
  /// **'Quantity to Transfer'**
  String get invQtyToTransfer;

  /// No description provided for @invTransferStock.
  ///
  /// In en, this message translates to:
  /// **'Transfer Stock'**
  String get invTransferStock;

  /// No description provided for @invAddIn.
  ///
  /// In en, this message translates to:
  /// **'Add In'**
  String get invAddIn;

  /// No description provided for @invAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get invAdjust;

  /// No description provided for @invTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get invTransfer;

  /// No description provided for @invVendorDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get invVendorDeactivate;

  /// No description provided for @bizManageLabel.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get bizManageLabel;

  /// No description provided for @bizQuickLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'QUICK LINKS'**
  String get bizQuickLinksLabel;

  /// No description provided for @bizShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get bizShopsTitle;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @bizActiveBranch.
  ///
  /// In en, this message translates to:
  /// **'Active branch'**
  String get bizActiveBranch;

  /// No description provided for @bizActiveBranches.
  ///
  /// In en, this message translates to:
  /// **'Active branches'**
  String get bizActiveBranches;

  /// No description provided for @bizProductsItem.
  ///
  /// In en, this message translates to:
  /// **'Products item'**
  String get bizProductsItem;

  /// No description provided for @bizProductsItems.
  ///
  /// In en, this message translates to:
  /// **'Products items'**
  String get bizProductsItems;

  /// No description provided for @bizUserSingular.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get bizUserSingular;

  /// No description provided for @bizUserPlural.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get bizUserPlural;

  /// No description provided for @bizReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and search all transactions'**
  String get bizReportSubtitle;

  /// No description provided for @bizCreateMyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create My Business'**
  String get bizCreateMyBusiness;

  /// No description provided for @bizAddFirstShop.
  ///
  /// In en, this message translates to:
  /// **'Add First Shop'**
  String get bizAddFirstShop;

  /// No description provided for @bizFieldBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get bizFieldBusinessName;

  /// No description provided for @bizFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bizFieldAddress;

  /// No description provided for @bizFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get bizFieldPhone;

  /// No description provided for @bizFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bizFieldEmail;

  /// No description provided for @bizInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get bizInfoTitle;

  /// No description provided for @bizInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic profile and contact details'**
  String get bizInfoSubtitle;

  /// No description provided for @bizDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Business?'**
  String get bizDeactivateTitle;

  /// No description provided for @bizFieldShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get bizFieldShopName;

  /// No description provided for @shopManagement.
  ///
  /// In en, this message translates to:
  /// **'Shop Management'**
  String get shopManagement;

  /// No description provided for @shopStatTotalShops.
  ///
  /// In en, this message translates to:
  /// **'Total Shops'**
  String get shopStatTotalShops;

  /// No description provided for @shopStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shopStatActive;

  /// No description provided for @shopStatInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get shopStatInactive;

  /// No description provided for @bizStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get bizStatusLabel;

  /// No description provided for @bizAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bizAddressLabel;

  /// No description provided for @bizPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get bizPhoneLabel;

  /// No description provided for @bizEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bizEmailLabel;

  /// No description provided for @bizShopsLabel.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get bizShopsLabel;

  /// No description provided for @addShop.
  ///
  /// In en, this message translates to:
  /// **'Add Shop'**
  String get addShop;

  /// No description provided for @noShopsYet.
  ///
  /// In en, this message translates to:
  /// **'No shops yet'**
  String get noShopsYet;

  /// No description provided for @firstShopMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first shop location to start managing products, sales, and cashiers.'**
  String get firstShopMessage;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @newShop.
  ///
  /// In en, this message translates to:
  /// **'New Shop'**
  String get newShop;

  /// No description provided for @shopAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shop added successfully'**
  String get shopAddedSuccessfully;

  /// No description provided for @mainBranchHint.
  ///
  /// In en, this message translates to:
  /// **'Main Branch'**
  String get mainBranchHint;

  /// No description provided for @shopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop name is required'**
  String get shopNameRequired;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @khartoumCentreHint.
  ///
  /// In en, this message translates to:
  /// **'Khartoum Centre'**
  String get khartoumCentreHint;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// No description provided for @editShop.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get editShop;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @createStaffAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Only cashier and manager accounts can be created here.'**
  String get createStaffAccountMessage;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ali Hassan'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @invalidRoleSelected.
  ///
  /// In en, this message translates to:
  /// **'Invalid role selected'**
  String get invalidRoleSelected;

  /// No description provided for @assignCashierToShopRequired.
  ///
  /// In en, this message translates to:
  /// **'Please assign this cashier to a shop.'**
  String get assignCashierToShopRequired;

  /// No description provided for @userAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get userAddedSuccessfully;

  /// No description provided for @autoAssignCashierToShop.
  ///
  /// In en, this message translates to:
  /// **'Will be assigned to {shopName} automatically.'**
  String autoAssignCashierToShop(String shopName);

  /// No description provided for @selectShop.
  ///
  /// In en, this message translates to:
  /// **'Select a shop'**
  String get selectShop;

  /// No description provided for @cashierShopRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Cashiers must be assigned to a shop to process sales.'**
  String get cashierShopRequiredMessage;

  /// No description provided for @cashierAssignedToShop.
  ///
  /// In en, this message translates to:
  /// **'Cashier will be assigned to {shopName}.'**
  String cashierAssignedToShop(String shopName);

  /// No description provided for @thisShop.
  ///
  /// In en, this message translates to:
  /// **'this shop'**
  String get thisShop;

  /// No description provided for @adminRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Full access — can manage everything including users and settings.'**
  String get adminRoleHint;

  /// No description provided for @managerRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Can view reports, manage inventory and orders.'**
  String get managerRoleHint;

  /// No description provided for @cashierRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Can process sales and manage the POS terminal.'**
  String get cashierRoleHint;

  /// No description provided for @editStaffAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Only cashier and manager roles can be assigned from here.'**
  String get editStaffAccountMessage;

  /// No description provided for @adminRoleCannotBeAssigned.
  ///
  /// In en, this message translates to:
  /// **'Admin role cannot be assigned from the app'**
  String get adminRoleCannotBeAssigned;

  /// No description provided for @invalidUserSelected.
  ///
  /// In en, this message translates to:
  /// **'Invalid user selected'**
  String get invalidUserSelected;

  /// No description provided for @userUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdatedSuccessfully;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @unassignedCashierMessage.
  ///
  /// In en, this message translates to:
  /// **'This cashier is not assigned to any shop and cannot process sales.'**
  String get unassignedCashierMessage;

  /// No description provided for @cashierAssignedToShopDetailed.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {shopName}. Cashier can process sales at this shop.'**
  String cashierAssignedToShopDetailed(String shopName);

  /// No description provided for @managerAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Managers are not assigned to a single shop. They can manage business operations based on their permissions.'**
  String get managerAccessMessage;

  /// No description provided for @userDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deactivated successfully'**
  String get userDeactivatedSuccessfully;

  /// No description provided for @deactivateUserMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will lose access immediately. You can reactivate them later.'**
  String deactivateUserMessage(String name);

  /// No description provided for @invalidUserId.
  ///
  /// In en, this message translates to:
  /// **'Invalid user ID'**
  String get invalidUserId;

  /// No description provided for @thisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get thisUser;

  /// No description provided for @noCashiersYet.
  ///
  /// In en, this message translates to:
  /// **'No cashiers yet'**
  String get noCashiersYet;

  /// No description provided for @noCashiersYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first cashier so your team can start processing sales from the POS.'**
  String get noCashiersYetDescription;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @managerAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Can manage inventory, reports and operations'**
  String get managerAccessHint;

  /// No description provided for @cashierAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Can process sales and use POS terminal'**
  String get cashierAccessHint;

  /// No description provided for @adminAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Can manage business settings and staff access'**
  String get adminAccessHint;

  /// No description provided for @staffAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Staff account'**
  String get staffAccountHint;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @nothingMatchesQuery.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String nothingMatchesQuery(String query);

  /// No description provided for @tryAnotherCategoryOrAddProducts.
  ///
  /// In en, this message translates to:
  /// **'Try another category or add products first.'**
  String get tryAnotherCategoryOrAddProducts;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @bankak.
  ///
  /// In en, this message translates to:
  /// **'Bankak'**
  String get bankak;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @bankakReadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Bankak ready · Account {account}'**
  String bankakReadyAccount(String account);

  /// No description provided for @bankakAccountSetupBanner.
  ///
  /// In en, this message translates to:
  /// **'Bankak account is not set up. Tap to open settings.'**
  String get bankakAccountSetupBanner;

  /// No description provided for @bankakAccountNotSetUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Bankak account is not set up. Go to Settings and add your account number first.'**
  String get bankakAccountNotSetUpMessage;

  /// No description provided for @cashierNotAssignedToShopMessage.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to a shop. Contact your manager.'**
  String get cashierNotAssignedToShopMessage;

  /// No description provided for @noShopFoundRefreshMessage.
  ///
  /// In en, this message translates to:
  /// **'No shop found. Please refresh and try again.'**
  String get noShopFoundRefreshMessage;

  /// No description provided for @clearCartQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get clearCartQuestion;

  /// No description provided for @clearCartDescription.
  ///
  /// In en, this message translates to:
  /// **'This will remove all items from the current sale.'**
  String get clearCartDescription;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reviewSale.
  ///
  /// In en, this message translates to:
  /// **'Review sale'**
  String get reviewSale;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewCart.
  ///
  /// In en, this message translates to:
  /// **'Review cart'**
  String get reviewCart;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get completeSale;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @eachPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String eachPrice(String price);

  /// No description provided for @failedToLoadSales.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sales'**
  String get failedToLoadSales;

  /// No description provided for @searchReceiptAmountPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Search receipt, amount, payment...'**
  String get searchReceiptAmountPaymentHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @allLoaded.
  ///
  /// In en, this message translates to:
  /// **'All loaded'**
  String get allLoaded;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s'**
  String get todaysSales;

  /// No description provided for @noMatchingSales.
  ///
  /// In en, this message translates to:
  /// **'No matching sales'**
  String get noMatchingSales;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @noSalesToday.
  ///
  /// In en, this message translates to:
  /// **'No sales today'**
  String get noSalesToday;

  /// No description provided for @salesMadeTodayWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Sales made today will appear here'**
  String get salesMadeTodayWillAppearHere;

  /// No description provided for @noPendingSales.
  ///
  /// In en, this message translates to:
  /// **'No pending sales'**
  String get noPendingSales;

  /// No description provided for @allOfflineSalesSynced.
  ///
  /// In en, this message translates to:
  /// **'All offline sales have been synced'**
  String get allOfflineSalesSynced;

  /// No description provided for @noCompletedSales.
  ///
  /// In en, this message translates to:
  /// **'No completed sales'**
  String get noCompletedSales;

  /// No description provided for @noReturnedSales.
  ///
  /// In en, this message translates to:
  /// **'No returned sales'**
  String get noReturnedSales;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @matchingSalesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Matching sales will appear here'**
  String get matchingSalesWillAppearHere;

  /// No description provided for @salesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Sales will appear here once you complete your first checkout'**
  String get salesWillAppearHere;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @partiallyReturned.
  ///
  /// In en, this message translates to:
  /// **'Partially returned'**
  String get partiallyReturned;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @todayWithTime.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayWithTime(String time);

  /// No description provided for @yesterdayWithTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayWithTime(String time);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @allLoadedSales.
  ///
  /// In en, this message translates to:
  /// **'All loaded sales'**
  String get allLoadedSales;

  /// No description provided for @todaysSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get todaysSalesCount;

  /// No description provided for @completedSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Completed sales'**
  String get completedSalesCount;

  /// No description provided for @returnedSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Returned sales'**
  String get returnedSalesCount;

  /// No description provided for @pendingSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Pending sales'**
  String get pendingSalesCount;

  /// No description provided for @allLoadedRevenue.
  ///
  /// In en, this message translates to:
  /// **'All loaded revenue'**
  String get allLoadedRevenue;

  /// No description provided for @todaysRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s revenue'**
  String get todaysRevenue;

  /// No description provided for @completedRevenue.
  ///
  /// In en, this message translates to:
  /// **'Completed revenue'**
  String get completedRevenue;

  /// No description provided for @returnedRevenue.
  ///
  /// In en, this message translates to:
  /// **'Returned revenue'**
  String get returnedRevenue;

  /// No description provided for @pendingRevenue.
  ///
  /// In en, this message translates to:
  /// **'Pending revenue'**
  String get pendingRevenue;

  /// No description provided for @receiptNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'RECEIPT NUMBER'**
  String get receiptNumberLabel;

  /// No description provided for @temporaryReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'TEMPORARY REFERENCE'**
  String get temporaryReferenceLabel;

  /// No description provided for @salePendingSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'This sale is pending sync. Returns and final receipt number are only available after the sale syncs to the server.'**
  String get salePendingSyncDescription;

  /// No description provided for @saleAlreadyRefunded.
  ///
  /// In en, this message translates to:
  /// **'This sale has already been refunded.'**
  String get saleAlreadyRefunded;

  /// No description provided for @preparingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Preparing receipt...'**
  String get preparingReceipt;

  /// No description provided for @shareReceiptPdf.
  ///
  /// In en, this message translates to:
  /// **'Share receipt PDF'**
  String get shareReceiptPdf;

  /// No description provided for @receiptPdfShareHint.
  ///
  /// In en, this message translates to:
  /// **'The receipt will be shared as a PDF file. Choose WhatsApp from the share options.'**
  String get receiptPdfShareHint;

  /// No description provided for @noItemDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No item details available'**
  String get noItemDetailsAvailable;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @amanaReceipt.
  ///
  /// In en, this message translates to:
  /// **'AmanaPOS Receipt'**
  String get amanaReceipt;

  /// No description provided for @salesReceipt.
  ///
  /// In en, this message translates to:
  /// **'Sales Receipt'**
  String get salesReceipt;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @offlineSalePdfWarning.
  ///
  /// In en, this message translates to:
  /// **'Offline sale - final server confirmation may still be pending.'**
  String get offlineSalePdfWarning;

  /// No description provided for @thankYouForPurchase.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase.'**
  String get thankYouForPurchase;

  /// No description provided for @poweredByAmanaPOS.
  ///
  /// In en, this message translates to:
  /// **'Powered by AmanaPOS'**
  String get poweredByAmanaPOS;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process return'**
  String get processReturn;

  /// No description provided for @returnSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Receipt number, amount...'**
  String get returnSearchHint;

  /// No description provided for @returnSearchHelper.
  ///
  /// In en, this message translates to:
  /// **'Receipt number, amount, or customer name'**
  String get returnSearchHelper;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @returnPendingSyncCannotReturn.
  ///
  /// In en, this message translates to:
  /// **'Pending sync — cannot return yet'**
  String get returnPendingSyncCannotReturn;

  /// No description provided for @returnAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'Already {status}'**
  String returnAlreadyProcessed(String status);

  /// No description provided for @originalSale.
  ///
  /// In en, this message translates to:
  /// **'Original sale'**
  String get originalSale;

  /// No description provided for @tapItemsToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap items to select'**
  String get tapItemsToSelect;

  /// No description provided for @refundTotal.
  ///
  /// In en, this message translates to:
  /// **'Refund total'**
  String get refundTotal;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @selectItemsToReturn.
  ///
  /// In en, this message translates to:
  /// **'Select items to return'**
  String get selectItemsToReturn;

  /// Shows number of items selected out of total
  ///
  /// In en, this message translates to:
  /// **'{selectedCount} of {totalCount} items selected'**
  String itemsSelected(Object selectedCount, Object totalCount);

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'sold'**
  String get sold;

  /// No description provided for @returnProcessed.
  ///
  /// In en, this message translates to:
  /// **'Return processed!'**
  String get returnProcessed;

  /// No description provided for @stockRestored.
  ///
  /// In en, this message translates to:
  /// **'Stock restored'**
  String get stockRestored;

  /// No description provided for @receiptReady.
  ///
  /// In en, this message translates to:
  /// **'Receipt ready to share'**
  String get receiptReady;

  /// No description provided for @returnReference.
  ///
  /// In en, this message translates to:
  /// **'Return reference'**
  String get returnReference;

  /// No description provided for @noReturnedItems.
  ///
  /// In en, this message translates to:
  /// **'No returned items found'**
  String get noReturnedItems;

  /// No description provided for @totalRefunded.
  ///
  /// In en, this message translates to:
  /// **'Total refunded'**
  String get totalRefunded;

  /// No description provided for @returnReceipt.
  ///
  /// In en, this message translates to:
  /// **'Return receipt'**
  String get returnReceipt;

  /// No description provided for @ref.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get ref;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @cashRefund.
  ///
  /// In en, this message translates to:
  /// **'Cash refund'**
  String get cashRefund;

  /// No description provided for @settingsSynced.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get settingsSynced;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get commonSetup;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @settingsBankakNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured — add Bankak to accept sales'**
  String get settingsBankakNotConfigured;

  /// No description provided for @settingsBankakReady.
  ///
  /// In en, this message translates to:
  /// **'Account {account} · ready for POS sales'**
  String settingsBankakReady(String account);

  /// No description provided for @settingsProfileSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Name, email and contact details'**
  String get settingsProfileSubtitleFallback;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Make sure all your sales are synced before signing out. Offline sales that have not synced will be lost.'**
  String get settingsSignOutMessage;

  /// No description provided for @noBusinessesYet.
  ///
  /// In en, this message translates to:
  /// **'No businesses yet'**
  String get noBusinessesYet;

  /// No description provided for @createFirstBusinessToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Create your first business to get started.'**
  String get createFirstBusinessToGetStarted;

  /// No description provided for @addBusiness.
  ///
  /// In en, this message translates to:
  /// **'Add Business'**
  String get addBusiness;

  /// No description provided for @noStockEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No stock entries yet'**
  String get noStockEntriesYet;

  /// No description provided for @addStockToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Add stock for your products to start tracking inventory.'**
  String get addStockToStartTracking;

  /// No description provided for @noHealthyStockItems.
  ///
  /// In en, this message translates to:
  /// **'No healthy stock items'**
  String get noHealthyStockItems;

  /// No description provided for @noProductsInHealthyStockState.
  ///
  /// In en, this message translates to:
  /// **'No products are currently in a healthy stock state.'**
  String get noProductsInHealthyStockState;

  /// No description provided for @noLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'No low stock items'**
  String get noLowStockItems;

  /// No description provided for @noProductsLowOnStock.
  ///
  /// In en, this message translates to:
  /// **'Everything looks good. No products are currently low on stock.'**
  String get noProductsLowOnStock;

  /// No description provided for @noOutOfStockItems.
  ///
  /// In en, this message translates to:
  /// **'No out of stock items'**
  String get noOutOfStockItems;

  /// No description provided for @noProductsOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Great. No products are currently out of stock.'**
  String get noProductsOutOfStock;

  /// No description provided for @addStock.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStock;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @allCaughtUpNewNotificationsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up. New notifications will appear here.'**
  String get allCaughtUpNewNotificationsWillAppearHere;

  /// No description provided for @salesViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get salesViewTransactions;

  /// No description provided for @salesViewReports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Statistics'**
  String get salesViewReports;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @avgSale.
  ///
  /// In en, this message translates to:
  /// **'Avg sale'**
  String get avgSale;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @reportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports & Statistics are coming soon.'**
  String get reportsComingSoon;

  /// No description provided for @reportsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsRevenue;

  /// No description provided for @reportsGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get reportsGross;

  /// No description provided for @reportsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsNet;

  /// No description provided for @revenueAndSalesTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue & Sales Trend'**
  String get revenueAndSalesTrend;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsTitle;

  /// No description provided for @peakHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Hours'**
  String get peakHoursTitle;

  /// No description provided for @topProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Products'**
  String get topProductsTitle;

  /// No description provided for @topCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get topCategoriesTitle;

  /// No description provided for @dayOfWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get dayOfWeekTitle;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// No description provided for @reportsNoSalesInRange.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period.'**
  String get reportsNoSalesInRange;

  /// No description provided for @reportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load report.'**
  String get reportsLoadError;

  /// No description provided for @reportsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh report'**
  String get reportsRefresh;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @reportsNetSales.
  ///
  /// In en, this message translates to:
  /// **'Net Sales'**
  String get reportsNetSales;

  /// No description provided for @reportsSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsSalesCount;

  /// No description provided for @searchSalesHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search by receipt or customer'**
  String get searchSalesHistoryHint;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @taxWithRate.
  ///
  /// In en, this message translates to:
  /// **'Tax ({taxName} {taxRate}%)'**
  String taxWithRate(String taxName, String taxRate);

  /// No description provided for @taxWithRatePercent.
  ///
  /// In en, this message translates to:
  /// **'Tax ({taxRate}%)'**
  String taxWithRatePercent(String taxRate);

  /// No description provided for @totalInclTax.
  ///
  /// In en, this message translates to:
  /// **'Total (incl. {taxName} {taxRate}%)'**
  String totalInclTax(String taxName, String taxRate);

  /// No description provided for @taxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Tax included'**
  String get taxIncluded;

  /// No description provided for @taxCollected.
  ///
  /// In en, this message translates to:
  /// **'Tax Collected'**
  String get taxCollected;

  /// No description provided for @taxDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tax disabled'**
  String get taxDisabled;

  /// No description provided for @pricesIncludeTax.
  ///
  /// In en, this message translates to:
  /// **'Prices include tax'**
  String get pricesIncludeTax;

  /// No description provided for @pricesExcludeTax.
  ///
  /// In en, this message translates to:
  /// **'Prices exclude tax'**
  String get pricesExcludeTax;

  /// No description provided for @posRowInStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String posRowInStock(String count);

  /// No description provided for @posRowLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock · {count}'**
  String posRowLowStock(String count);

  /// No description provided for @posRowOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get posRowOutOfStock;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @exactAmount.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exactAmount;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change due'**
  String get changeDue;

  /// No description provided for @posKeypad.
  ///
  /// In en, this message translates to:
  /// **'Keypad'**
  String get posKeypad;

  /// No description provided for @posItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get posItems;

  /// No description provided for @posCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get posCustomAmount;

  /// No description provided for @posEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get posEnterAmount;

  /// No description provided for @posAddToTicket.
  ///
  /// In en, this message translates to:
  /// **'Add to ticket'**
  String get posAddToTicket;

  /// No description provided for @posAddedToTicket.
  ///
  /// In en, this message translates to:
  /// **'Added to ticket'**
  String get posAddedToTicket;

  /// No description provided for @posAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get posAddNote;

  /// No description provided for @posNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What is it for?'**
  String get posNoteHint;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number. We\'ll text you a 6-digit code.'**
  String get signInSubtitle;

  /// No description provided for @signInInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number, for example 912 345 678.'**
  String get signInInvalidNumber;

  /// No description provided for @signInNeedAccess.
  ///
  /// In en, this message translates to:
  /// **'Need access or want to register? Contact AmanaPOS support.'**
  String get signInNeedAccess;

  /// No description provided for @countryTitle.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryTitle;

  /// No description provided for @countrySudan.
  ///
  /// In en, this message translates to:
  /// **'Sudan'**
  String get countrySudan;

  /// No description provided for @countryUae.
  ///
  /// In en, this message translates to:
  /// **'UAE'**
  String get countryUae;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String codeSentTo(String phone);

  /// No description provided for @codeWrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong number?'**
  String get codeWrongNumber;

  /// No description provided for @codeResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String codeResendIn(String time);

  /// No description provided for @codeVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get codeVerifying;

  /// No description provided for @codeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get codeVerified;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use it to unlock AmanaPOS.'**
  String get pinCreateSubtitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get pinConfirmTitle;

  /// No description provided for @pinConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter it once more.'**
  String get pinConfirmSubtitle;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get pinEnterTitle;

  /// No description provided for @pinWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String pinWelcomeBack(String name);

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match. Start again.'**
  String get pinMismatch;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get pinWrong;

  /// No description provided for @pinTaken.
  ///
  /// In en, this message translates to:
  /// **'This PIN is already in use. Choose another.'**
  String get pinTaken;

  /// No description provided for @pinUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get pinUnavailable;

  /// No description provided for @pinNotYou.
  ///
  /// In en, this message translates to:
  /// **'Not {name}?'**
  String pinNotYou(String name);

  /// No description provided for @pinUseDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get pinUseDifferentAccount;

  /// No description provided for @pinForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN?'**
  String get pinForgot;

  /// No description provided for @pinLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get pinLockedTitle;

  /// No description provided for @pinLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try again in {time}.'**
  String pinLockedSubtitle(String time);

  /// No description provided for @pinCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get pinCurrentTitle;

  /// No description provided for @pinCurrentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you before changing your PIN.'**
  String get pinCurrentSubtitle;

  /// No description provided for @pinNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get pinNewTitle;

  /// No description provided for @pinNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new 4-digit PIN.'**
  String get pinNewSubtitle;

  /// No description provided for @pinConfirmNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get pinConfirmNewTitle;

  /// No description provided for @pinUpdated.
  ///
  /// In en, this message translates to:
  /// **'PIN updated.'**
  String get pinUpdated;

  /// No description provided for @pinBiometricFace.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get pinBiometricFace;

  /// No description provided for @pinBiometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get pinBiometricFingerprint;

  /// No description provided for @pinBiometricGeneric.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get pinBiometricGeneric;

  /// No description provided for @pinBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock AmanaPOS'**
  String get pinBiometricReason;

  /// No description provided for @pinBiometricEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Use {method} to unlock?'**
  String pinBiometricEnableTitle(String method);

  /// No description provided for @pinBiometricEnableBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock AmanaPOS in a glance. Your PIN still works any time.'**
  String get pinBiometricEnableBody;

  /// No description provided for @pinBiometricEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on {method}'**
  String pinBiometricEnable(String method);

  /// No description provided for @pinBiometricNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pinBiometricNotNow;

  /// No description provided for @menuLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get menuLock;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @homeStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get homeStatusLive;

  /// No description provided for @homeStatusCached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get homeStatusCached;

  /// No description provided for @homeStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline sales included'**
  String get homeStatusOffline;

  /// No description provided for @homeGrossSales.
  ///
  /// In en, this message translates to:
  /// **'Gross sales'**
  String get homeGrossSales;

  /// No description provided for @homeStatSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get homeStatSales;

  /// No description provided for @homeStatAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get homeStatAverage;

  /// No description provided for @homeStatRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get homeStatRefunds;

  /// No description provided for @homePayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get homePayments;

  /// No description provided for @homeTopSellers.
  ///
  /// In en, this message translates to:
  /// **'Top sellers'**
  String get homeTopSellers;

  /// No description provided for @homeManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get homeManage;

  /// No description provided for @homeSoldQty.
  ///
  /// In en, this message translates to:
  /// **'{qty} sold'**
  String homeSoldQty(String qty);

  /// No description provided for @homeShopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 branch} other{{count} branches}}'**
  String homeShopsCount(int count);

  /// No description provided for @homeProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String homeProductsCount(int count);

  /// No description provided for @homeUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 user} other{{count} users}}'**
  String homeUsersCount(int count);

  /// No description provided for @homeNoSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales yet today'**
  String get homeNoSalesTitle;

  /// No description provided for @homeNoSalesBody.
  ///
  /// In en, this message translates to:
  /// **'Sales you make will show up here, hour by hour.'**
  String get homeNoSalesBody;

  /// No description provided for @homeStartSelling.
  ///
  /// In en, this message translates to:
  /// **'Start selling'**
  String get homeStartSelling;

  /// No description provided for @homePlanNone.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get homePlanNone;

  /// No description provided for @homePlanContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support to activate your plan'**
  String get homePlanContact;

  /// No description provided for @homePlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get homePlanFree;

  /// No description provided for @homePlanPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid plan'**
  String get homePlanPaid;

  /// No description provided for @homePlanInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get homePlanInactive;

  /// No description provided for @homePlanNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get homePlanNoExpiry;

  /// No description provided for @homePlanExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get homePlanExpired;

  /// No description provided for @homePlanDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String homePlanDaysLeft(int count);

  /// No description provided for @homePlanLimits.
  ///
  /// In en, this message translates to:
  /// **'Shops {shops} · Products {products} · Users {users}'**
  String homePlanLimits(String shops, String products, String users);

  /// No description provided for @homePlanUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get homePlanUnlimited;

  /// No description provided for @homePayCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get homePayCard;

  /// No description provided for @homePayBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get homePayBankTransfer;

  /// No description provided for @homePayWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get homePayWallet;

  /// No description provided for @homePayLoyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty points'**
  String get homePayLoyalty;

  /// No description provided for @homePayCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get homePayCredit;

  /// No description provided for @homePaySplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get homePaySplit;

  /// No description provided for @homePayOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get homePayOther;

  /// No description provided for @homePlanPriceMonthly.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String homePlanPriceMonthly(String price);

  /// No description provided for @homePlanPriceYearly.
  ///
  /// In en, this message translates to:
  /// **'{price} a year'**
  String homePlanPriceYearly(String price);

  /// No description provided for @homeReportsHint.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get homeReportsHint;

  /// No description provided for @pcSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, SKU or barcode'**
  String get pcSearchHint;

  /// No description provided for @pcCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String pcCount(String count);

  /// No description provided for @pcChipCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pcChipCategory;

  /// No description provided for @pcChipLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get pcChipLow;

  /// No description provided for @pcChipOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get pcChipOut;

  /// No description provided for @pcInStock.
  ///
  /// In en, this message translates to:
  /// **'{qty} in stock'**
  String pcInStock(String qty);

  /// No description provided for @pcLeft.
  ///
  /// In en, this message translates to:
  /// **'{qty} left'**
  String pcLeft(String qty);

  /// No description provided for @pcOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get pcOutOfStock;

  /// No description provided for @pcSwipeStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get pcSwipeStock;

  /// No description provided for @pcNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get pcNoMatches;

  /// No description provided for @pcNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another name, SKU or barcode.'**
  String get pcNoMatchesBody;

  /// No description provided for @pcErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load products'**
  String get pcErrorTitle;

  /// No description provided for @pcErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get pcErrorBody;

  /// No description provided for @pcAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get pcAllCategories;

  /// No description provided for @pcShowingSaved.
  ///
  /// In en, this message translates to:
  /// **'Showing saved products'**
  String get pcShowingSaved;

  /// No description provided for @pcDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String pcDeleteTitle(String name);

  /// No description provided for @pcDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your catalog. Past sales keep their records.'**
  String get pcDeleteBody;

  /// No description provided for @pcDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get pcDeleted;

  /// No description provided for @pcUpdateStock.
  ///
  /// In en, this message translates to:
  /// **'Update stock'**
  String get pcUpdateStock;

  /// No description provided for @pcByShop.
  ///
  /// In en, this message translates to:
  /// **'By shop'**
  String get pcByShop;

  /// No description provided for @pcDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pcDetails;

  /// No description provided for @pcUnitsShort.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get pcUnitsShort;

  /// No description provided for @pcNoStockYet.
  ///
  /// In en, this message translates to:
  /// **'No stock recorded yet'**
  String get pcNoStockYet;

  /// No description provided for @pcStockNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Stock is not tracked for this product'**
  String get pcStockNotTracked;

  /// No description provided for @usAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get usAdd;

  /// No description provided for @usRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get usRemove;

  /// No description provided for @usCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get usCount;

  /// No description provided for @usMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get usMove;

  /// No description provided for @usHintAdd.
  ///
  /// In en, this message translates to:
  /// **'New stock arrived or was found.'**
  String get usHintAdd;

  /// No description provided for @usHintRemove.
  ///
  /// In en, this message translates to:
  /// **'Damaged, lost or used up.'**
  String get usHintRemove;

  /// No description provided for @usHintCount.
  ///
  /// In en, this message translates to:
  /// **'Type what you counted on the shelf. Stock is set to this number.'**
  String get usHintCount;

  /// No description provided for @usHintMove.
  ///
  /// In en, this message translates to:
  /// **'Send stock to another shop.'**
  String get usHintMove;

  /// No description provided for @usFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get usFrom;

  /// No description provided for @usTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get usTo;

  /// No description provided for @usAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get usAfter;

  /// No description provided for @usExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get usExpiryDate;

  /// No description provided for @usNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get usNote;

  /// No description provided for @usSaveAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {qty}'**
  String usSaveAdd(String qty);

  /// No description provided for @usSaveRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {qty}'**
  String usSaveRemove(String qty);

  /// No description provided for @usSaveCount.
  ///
  /// In en, this message translates to:
  /// **'Set count to {qty}'**
  String usSaveCount(String qty);

  /// No description provided for @usSaveMove.
  ///
  /// In en, this message translates to:
  /// **'Move {qty}'**
  String usSaveMove(String qty);

  /// No description provided for @usSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get usSaved;

  /// No description provided for @usNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock in this shop'**
  String get usNotEnough;

  /// No description provided for @usPickDifferentShop.
  ///
  /// In en, this message translates to:
  /// **'Choose two different shops'**
  String get usPickDifferentShop;

  /// No description provided for @usEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity'**
  String get usEnterQuantity;

  /// No description provided for @pfTrackStock.
  ///
  /// In en, this message translates to:
  /// **'Track stock'**
  String get pfTrackStock;

  /// No description provided for @pfTrackStockHint.
  ///
  /// In en, this message translates to:
  /// **'Counts stock and warns when it runs low.'**
  String get pfTrackStockHint;

  /// No description provided for @pfStartingStock.
  ///
  /// In en, this message translates to:
  /// **'Starting stock'**
  String get pfStartingStock;

  /// No description provided for @pfMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get pfMoreDetails;

  /// No description provided for @pfFewerDetails.
  ///
  /// In en, this message translates to:
  /// **'Fewer details'**
  String get pfFewerDetails;

  /// No description provided for @pfLowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert'**
  String get pfLowStockAlert;

  /// No description provided for @pfExpiryAlert.
  ///
  /// In en, this message translates to:
  /// **'Expiry alert'**
  String get pfExpiryAlert;

  /// No description provided for @pfExpiryDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days before'**
  String pfExpiryDays(String days);

  /// No description provided for @pfAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get pfAddPhoto;

  /// No description provided for @pfChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get pfChangePhoto;

  /// No description provided for @pfDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get pfDeleteProduct;

  /// No description provided for @pfCategoryLockedNote.
  ///
  /// In en, this message translates to:
  /// **'A product cannot move to another category.'**
  String get pfCategoryLockedNote;

  /// No description provided for @pfCategoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get pfCategoryNameHint;

  /// No description provided for @pfGeneralHint.
  ///
  /// In en, this message translates to:
  /// **'Used when you pick nothing'**
  String get pfGeneralHint;

  /// No description provided for @pfEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get pfEnterName;

  /// No description provided for @pfEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get pfEnterPrice;

  /// No description provided for @pfStockRowValue.
  ///
  /// In en, this message translates to:
  /// **'{qty} {unit}'**
  String pfStockRowValue(String qty, String unit);

  /// No description provided for @pfUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pfUnit;

  /// No description provided for @pfBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get pfBarcode;

  /// No description provided for @pfCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get pfCostPrice;

  /// No description provided for @pfSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get pfSaving;

  /// No description provided for @ctCountTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String ctCountTitle(String count);

  /// No description provided for @ctEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a category to group products and find them faster.'**
  String get ctEmptyBody;

  /// No description provided for @ctDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get ctDelete;

  /// No description provided for @ctDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Its products stay in your catalog without a category.'**
  String get ctDeleteNote;

  /// No description provided for @ctInThis.
  ///
  /// In en, this message translates to:
  /// **'{count} products in this category'**
  String ctInThis(String count);

  /// No description provided for @ctNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get ctNoProducts;

  /// No description provided for @ctNoProductsBody.
  ///
  /// In en, this message translates to:
  /// **'Products you add here will show up in this category.'**
  String get ctNoProductsBody;

  /// No description provided for @ctDescHint.
  ///
  /// In en, this message translates to:
  /// **'What goes in this category'**
  String get ctDescHint;

  /// No description provided for @ctEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name'**
  String get ctEnterName;

  /// No description provided for @stReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get stReceive;

  /// No description provided for @stReceiveHint.
  ///
  /// In en, this message translates to:
  /// **'Record a delivery'**
  String get stReceiveHint;

  /// No description provided for @stAddStock.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get stAddStock;

  /// No description provided for @stAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get stAttention;

  /// No description provided for @stExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get stExpiring;

  /// No description provided for @stAllGood.
  ///
  /// In en, this message translates to:
  /// **'Everything is in stock'**
  String get stAllGood;

  /// No description provided for @stAllGoodBody.
  ///
  /// In en, this message translates to:
  /// **'Low and out-of-stock products will show up here.'**
  String get stAllGoodBody;

  /// No description provided for @stVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get stVendors;

  /// No description provided for @stReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get stReceipts;

  /// No description provided for @stExpiryReport.
  ///
  /// In en, this message translates to:
  /// **'Expiry report'**
  String get stExpiryReport;

  /// No description provided for @stMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get stMore;

  /// No description provided for @fbOpeningStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Product created, but its starting stock was not saved. Add it with Update stock.'**
  String get fbOpeningStockWarning;

  /// No description provided for @fbCategoriesErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories'**
  String get fbCategoriesErrorTitle;

  /// No description provided for @fbInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, 0 or more'**
  String get fbInvalidNumber;

  /// No description provided for @fbInvalidDays.
  ///
  /// In en, this message translates to:
  /// **'Enter whole days, 1 or more'**
  String get fbInvalidDays;

  /// No description provided for @fbCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get fbCategoriesTitle;

  /// No description provided for @pcAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get pcAddProduct;

  /// No description provided for @pcEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start selling it.'**
  String get pcEmptyBody;

  /// No description provided for @pfNewProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get pfNewProduct;

  /// No description provided for @pfEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get pfEditProduct;

  /// No description provided for @pfName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pfName;

  /// No description provided for @pfNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get pfNewCategory;

  /// No description provided for @pfEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get pfEditCategory;

  /// No description provided for @sessionEndedSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again to continue.'**
  String get sessionEndedSignInAgain;

  /// No description provided for @shUnit.
  ///
  /// In en, this message translates to:
  /// **'SDG'**
  String get shUnit;

  /// No description provided for @shTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get shTitle;

  /// No description provided for @shSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search receipt, customer or phone'**
  String get shSearchHint;

  /// No description provided for @shCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}}'**
  String shCount(int count);

  /// No description provided for @shChipDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get shChipDate;

  /// No description provided for @shDateAny.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get shDateAny;

  /// No description provided for @shDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get shDateToday;

  /// No description provided for @shDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get shDateYesterday;

  /// No description provided for @shDateLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get shDateLast7;

  /// No description provided for @shDateMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get shDateMonth;

  /// No description provided for @shDateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get shDateCustom;

  /// No description provided for @shChipPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get shChipPayment;

  /// No description provided for @shPayAll.
  ///
  /// In en, this message translates to:
  /// **'All payments'**
  String get shPayAll;

  /// No description provided for @shPayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get shPayCash;

  /// No description provided for @shPayBankak.
  ///
  /// In en, this message translates to:
  /// **'Bankak'**
  String get shPayBankak;

  /// No description provided for @shPayCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get shPayCard;

  /// No description provided for @shChipStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get shChipStatus;

  /// No description provided for @shStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get shStatusAll;

  /// No description provided for @shStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get shStatusCompleted;

  /// No description provided for @shStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly returned'**
  String get shStatusPartial;

  /// No description provided for @shStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get shStatusReturned;

  /// No description provided for @shStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get shStatusCancelled;

  /// No description provided for @shChipUnsynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get shChipUnsynced;

  /// No description provided for @shPillNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get shPillNotSynced;

  /// No description provided for @shPillSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get shPillSyncFailed;

  /// No description provided for @shPillReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get shPillReturned;

  /// No description provided for @shPillPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly returned'**
  String get shPillPartial;

  /// No description provided for @shItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String shItems(int count);

  /// No description provided for @shWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get shWalkIn;

  /// No description provided for @shSwipeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get shSwipeReturn;

  /// No description provided for @shSwipeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get shSwipeReceipt;

  /// No description provided for @shEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get shEmptyTitle;

  /// No description provided for @shEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another receipt number, customer or filter.'**
  String get shEmptyBody;

  /// No description provided for @shClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get shClearFilters;

  /// No description provided for @shErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load sales'**
  String get shErrorTitle;

  /// No description provided for @shErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get shErrorBody;

  /// No description provided for @shTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get shTryAgain;

  /// No description provided for @shWhen.
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String shWhen(String day, String time);

  /// No description provided for @shReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get shReceipt;

  /// No description provided for @shDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get shDate;

  /// No description provided for @shCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get shCashier;

  /// No description provided for @shShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shShop;

  /// No description provided for @shCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get shCustomer;

  /// No description provided for @shPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get shPayment;

  /// No description provided for @shNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get shNote;

  /// No description provided for @shItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items · {count}'**
  String shItemsHeader(int count);

  /// No description provided for @shSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get shSubtotal;

  /// No description provided for @shDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get shDiscount;

  /// No description provided for @shTaxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes tax {rate}%'**
  String shTaxIncluded(String rate);

  /// No description provided for @shTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get shTax;

  /// No description provided for @shTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get shTotal;

  /// No description provided for @shReturnedTotal.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get shReturnedTotal;

  /// No description provided for @shNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get shNet;

  /// No description provided for @shReturnsHeader.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get shReturnsHeader;

  /// No description provided for @shReturnItems.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get shReturnItems;

  /// No description provided for @shShareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get shShareReceipt;

  /// No description provided for @shCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get shCopied;

  /// No description provided for @shLineReturned.
  ///
  /// In en, this message translates to:
  /// **'{qty} returned'**
  String shLineReturned(String qty);

  /// No description provided for @shBannerPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync. You can return this sale after it syncs.'**
  String get shBannerPending;

  /// No description provided for @shBannerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync this sale: {reason}'**
  String shBannerFailed(String reason);

  /// No description provided for @shBannerFailedNoReason.
  ///
  /// In en, this message translates to:
  /// **'Could not sync this sale.'**
  String get shBannerFailedNoReason;

  /// No description provided for @shBankakAccount.
  ///
  /// In en, this message translates to:
  /// **'Bankak ••• {last4}'**
  String shBankakAccount(String last4);

  /// No description provided for @shReceiptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the receipt. Try again.'**
  String get shReceiptFailed;

  /// No description provided for @rtTitle.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get rtTitle;

  /// No description provided for @rtSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get rtSelectAll;

  /// No description provided for @rtClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get rtClear;

  /// No description provided for @rtItemsToReturn.
  ///
  /// In en, this message translates to:
  /// **'Items to return'**
  String get rtItemsToReturn;

  /// No description provided for @rtSold.
  ///
  /// In en, this message translates to:
  /// **'Sold {qty}'**
  String rtSold(String qty);

  /// No description provided for @rtSoldReturned.
  ///
  /// In en, this message translates to:
  /// **'Sold {qty} · Returned {returned}'**
  String rtSoldReturned(String qty, String returned);

  /// No description provided for @rtQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity to return'**
  String get rtQuantity;

  /// No description provided for @rtUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {qty}'**
  String rtUpTo(String qty);

  /// No description provided for @rtReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get rtReason;

  /// No description provided for @rtOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get rtOptional;

  /// No description provided for @rtPayBack.
  ///
  /// In en, this message translates to:
  /// **'Pay back via'**
  String get rtPayBack;

  /// No description provided for @rtFooter.
  ///
  /// In en, this message translates to:
  /// **'Stock goes back on the shelf and the refund is counted in your reports.'**
  String get rtFooter;

  /// No description provided for @rtRefundButton.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}'**
  String rtRefundButton(String amount);

  /// No description provided for @rtPickItems.
  ///
  /// In en, this message translates to:
  /// **'Select items to return'**
  String get rtPickItems;

  /// No description provided for @rtConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}?'**
  String rtConfirmTitle(String amount);

  /// No description provided for @rtConfirmBodyCash.
  ///
  /// In en, this message translates to:
  /// **'Stock is restored. Give the customer {amount} in cash.'**
  String rtConfirmBodyCash(String amount);

  /// No description provided for @rtConfirmBodyOther.
  ///
  /// In en, this message translates to:
  /// **'Stock is restored. Send the customer {amount} by {method}.'**
  String rtConfirmBodyOther(String amount, String method);

  /// No description provided for @rtConfirmGo.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get rtConfirmGo;

  /// No description provided for @rtDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Return recorded'**
  String get rtDoneTitle;

  /// No description provided for @rtDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Stock is back on the shelf.'**
  String get rtDoneBody;

  /// No description provided for @rtReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get rtReference;

  /// No description provided for @rtShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get rtShareWhatsApp;

  /// No description provided for @rtFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the return. Try again.'**
  String get rtFailed;

  /// No description provided for @rtPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get rtPickTitle;

  /// No description provided for @rtPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the sale to return from.'**
  String get rtPickSubtitle;

  /// No description provided for @rtNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get rtNotSynced;

  /// No description provided for @rtAlreadyReturned.
  ///
  /// In en, this message translates to:
  /// **'Already returned'**
  String get rtAlreadyReturned;

  /// No description provided for @rpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get rpTitle;

  /// No description provided for @rpToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rpToday;

  /// No description provided for @rpYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get rpYesterday;

  /// No description provided for @rpWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get rpWeek;

  /// No description provided for @rpMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get rpMonth;

  /// No description provided for @rpCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get rpCustom;

  /// No description provided for @rpNetSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get rpNetSales;

  /// No description provided for @rpFromSales.
  ///
  /// In en, this message translates to:
  /// **'From {count} sales · average {avg}'**
  String rpFromSales(String count, String avg);

  /// No description provided for @rpGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get rpGross;

  /// No description provided for @rpReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get rpReturns;

  /// No description provided for @rpTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get rpTax;

  /// No description provided for @rpTrendHour.
  ///
  /// In en, this message translates to:
  /// **'Sales by hour'**
  String get rpTrendHour;

  /// No description provided for @rpTrendDay.
  ///
  /// In en, this message translates to:
  /// **'Sales by day'**
  String get rpTrendDay;

  /// No description provided for @rpBusiest.
  ///
  /// In en, this message translates to:
  /// **'Busiest'**
  String get rpBusiest;

  /// No description provided for @rpPayments.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get rpPayments;

  /// No description provided for @rpTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get rpTopProducts;

  /// No description provided for @rpTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get rpTopCategories;

  /// No description provided for @rpPeakHours.
  ///
  /// In en, this message translates to:
  /// **'Busiest hours'**
  String get rpPeakHours;

  /// No description provided for @rpBusiestDays.
  ///
  /// In en, this message translates to:
  /// **'Busiest days'**
  String get rpBusiestDays;

  /// No description provided for @rpSold.
  ///
  /// In en, this message translates to:
  /// **'{qty} sold'**
  String rpSold(String qty);

  /// No description provided for @rpFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get rpFrom;

  /// No description provided for @rpTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get rpTo;

  /// No description provided for @rpApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get rpApply;

  /// No description provided for @rpCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get rpCustomRange;

  /// No description provided for @rpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get rpEmptyTitle;

  /// No description provided for @rpEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick another range to see your numbers.'**
  String get rpEmptyBody;

  /// No description provided for @rpErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report'**
  String get rpErrorTitle;

  /// No description provided for @rpUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String rpUpdated(String time);

  /// No description provided for @rpOwnersOnly.
  ///
  /// In en, this message translates to:
  /// **'Reports is for owners only.'**
  String get rpOwnersOnly;

  /// No description provided for @homeSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get homeSalesHistory;

  /// No description provided for @homeSalesHint.
  ///
  /// In en, this message translates to:
  /// **'Receipts and returns'**
  String get homeSalesHint;

  /// No description provided for @homeReportsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Sales and performance'**
  String get homeReportsPerformance;

  /// No description provided for @fmOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get fmOptional;

  /// No description provided for @cuTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get cuTitle;

  /// No description provided for @cuCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer} other{{count} customers}}'**
  String cuCount(int count);

  /// No description provided for @cuCountInactive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer · inactive} other{{count} customers · inactive}}'**
  String cuCountInactive(int count);

  /// No description provided for @cuSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get cuSearch;

  /// No description provided for @cuChipActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get cuChipActive;

  /// No description provided for @cuChipInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get cuChipInactive;

  /// No description provided for @cuEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get cuEmptyTitle;

  /// No description provided for @cuEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save a customer once and attach them to a sale in a tap.'**
  String get cuEmptyBody;

  /// No description provided for @cuEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get cuEmptyAction;

  /// No description provided for @cuSwipeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cuSwipeEdit;

  /// No description provided for @cuSwipeDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get cuSwipeDeactivate;

  /// No description provided for @cuSwipeReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get cuSwipeReactivate;

  /// No description provided for @cuInactiveTag.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get cuInactiveTag;

  /// No description provided for @cuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cuEdit;

  /// No description provided for @cuCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get cuCall;

  /// No description provided for @cuWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get cuWhatsApp;

  /// No description provided for @cuEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cuEmailAction;

  /// No description provided for @cuTotalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total purchases'**
  String get cuTotalPurchases;

  /// No description provided for @cuLoyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty points'**
  String get cuLoyalty;

  /// No description provided for @cuSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since'**
  String get cuSince;

  /// No description provided for @cuContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get cuContact;

  /// No description provided for @cuPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cuPhone;

  /// No description provided for @cuEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cuEmail;

  /// No description provided for @cuAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get cuAddress;

  /// No description provided for @cuNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get cuNotes;

  /// No description provided for @cuDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate customer'**
  String get cuDeactivate;

  /// No description provided for @cuReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate customer'**
  String get cuReactivate;

  /// No description provided for @cuInactiveBanner.
  ///
  /// In en, this message translates to:
  /// **'Inactive. Hidden from search when selling.'**
  String get cuInactiveBanner;

  /// No description provided for @cuNew.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get cuNew;

  /// No description provided for @cuEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get cuEditTitle;

  /// No description provided for @cuName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cuName;

  /// No description provided for @cuMore.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get cuMore;

  /// No description provided for @cuLess.
  ///
  /// In en, this message translates to:
  /// **'Fewer details'**
  String get cuLess;

  /// No description provided for @cuPhoneFoot.
  ///
  /// In en, this message translates to:
  /// **'Used to find the customer and share receipts on WhatsApp.'**
  String get cuPhoneFoot;

  /// No description provided for @cuDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String cuDeactivateTitle(String name);

  /// No description provided for @cuDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will stop showing in the customer list. Past sales stay in history. You can reactivate any time.'**
  String cuDeactivateBody(String name);

  /// No description provided for @cuDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get cuDeactivateConfirm;

  /// No description provided for @cuErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load customers'**
  String get cuErrorTitle;

  /// No description provided for @cuErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get cuErrorBody;

  /// No description provided for @cuSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer saved'**
  String get cuSaved;

  /// No description provided for @cuDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Customer deactivated'**
  String get cuDeactivated;

  /// No description provided for @cuReactivated.
  ///
  /// In en, this message translates to:
  /// **'Customer reactivated'**
  String get cuReactivated;

  /// No description provided for @tmTitle.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tmTitle;

  /// No description provided for @tmCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String tmCount(int count);

  /// No description provided for @tmManagers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get tmManagers;

  /// No description provided for @tmCashiers.
  ///
  /// In en, this message translates to:
  /// **'Cashiers'**
  String get tmCashiers;

  /// No description provided for @tmInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get tmInvited;

  /// No description provided for @tmInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get tmInactive;

  /// No description provided for @tmNever.
  ///
  /// In en, this message translates to:
  /// **'Never signed in'**
  String get tmNever;

  /// No description provided for @tmEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No team yet'**
  String get tmEmptyTitle;

  /// No description provided for @tmEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add cashiers and managers. Each one signs in with their own phone.'**
  String get tmEmptyBody;

  /// No description provided for @tmEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add team member'**
  String get tmEmptyAction;

  /// No description provided for @tmSwipeDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get tmSwipeDeactivate;

  /// No description provided for @tmRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get tmRole;

  /// No description provided for @tmBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get tmBranch;

  /// No description provided for @tmLastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in'**
  String get tmLastSignIn;

  /// No description provided for @tmJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get tmJoined;

  /// No description provided for @tmCanSignIn.
  ///
  /// In en, this message translates to:
  /// **'Can sign in'**
  String get tmCanSignIn;

  /// No description provided for @tmCanSignInFoot.
  ///
  /// In en, this message translates to:
  /// **'Turn off to block sign-in right away. Their sales stay in history.'**
  String get tmCanSignInFoot;

  /// No description provided for @tmRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get tmRoleManager;

  /// No description provided for @tmRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get tmRoleCashier;

  /// No description provided for @tmRoleManagerDesc.
  ///
  /// In en, this message translates to:
  /// **'Sells, manages products and stock, sees reports. Cannot manage the team or billing.'**
  String get tmRoleManagerDesc;

  /// No description provided for @tmRoleCashierDesc.
  ///
  /// In en, this message translates to:
  /// **'Sells and processes returns. Sees only their own shift.'**
  String get tmRoleCashierDesc;

  /// No description provided for @tmNew.
  ///
  /// In en, this message translates to:
  /// **'New team member'**
  String get tmNew;

  /// No description provided for @tmFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get tmFullName;

  /// No description provided for @tmPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get tmPhone;

  /// No description provided for @tmSignFoot.
  ///
  /// In en, this message translates to:
  /// **'They sign in with a code sent to this phone. There is no password or PIN to set.'**
  String get tmSignFoot;

  /// No description provided for @tmDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String tmDeactivateTitle(String name);

  /// No description provided for @tmDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be signed out and can no longer sign in. Their sales stay in history.'**
  String tmDeactivateBody(String name);

  /// No description provided for @tmDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get tmDeactivateConfirm;

  /// No description provided for @tmToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tmToday;

  /// No description provided for @tmYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get tmYesterday;

  /// No description provided for @tmDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String tmDaysAgo(int count);

  /// No description provided for @tmErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the team'**
  String get tmErrorTitle;

  /// No description provided for @tmSaved.
  ///
  /// In en, this message translates to:
  /// **'Team member saved'**
  String get tmSaved;

  /// No description provided for @tmUpdated.
  ///
  /// In en, this message translates to:
  /// **'Team member updated'**
  String get tmUpdated;

  /// No description provided for @prnTestReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print a test receipt'**
  String get prnTestReceipt;

  /// No description provided for @prnForget.
  ///
  /// In en, this message translates to:
  /// **'Forget printer'**
  String get prnForget;

  /// No description provided for @prnOther.
  ///
  /// In en, this message translates to:
  /// **'Other printers'**
  String get prnOther;

  /// No description provided for @prnSearchNearby.
  ///
  /// In en, this message translates to:
  /// **'Search nearby'**
  String get prnSearchNearby;

  /// No description provided for @prnSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching nearby…'**
  String get prnSearching;

  /// No description provided for @prnAddByIp.
  ///
  /// In en, this message translates to:
  /// **'Add by IP address'**
  String get prnAddByIp;

  /// No description provided for @prnIpFoot.
  ///
  /// In en, this message translates to:
  /// **'For network printers that listen on port 9100, like the SAM4s GIANT-100.'**
  String get prnIpFoot;

  /// No description provided for @prnNearFoot.
  ///
  /// In en, this message translates to:
  /// **'Printers paired in your phone settings or found over Bluetooth appear here.'**
  String get prnNearFoot;

  /// No description provided for @prnNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network printer'**
  String get prnNetworkTitle;

  /// No description provided for @prnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get prnName;

  /// No description provided for @prnNoPrinterTitle.
  ///
  /// In en, this message translates to:
  /// **'No printer yet'**
  String get prnNoPrinterTitle;

  /// No description provided for @prnNoPrinterBody.
  ///
  /// In en, this message translates to:
  /// **'Search for a Bluetooth printer or add a network printer by its IP address.'**
  String get prnNoPrinterBody;

  /// No description provided for @prnBtOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off for Amana'**
  String get prnBtOffTitle;

  /// No description provided for @prnBtOffBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth in Settings to find printers near you.'**
  String get prnBtOffBody;

  /// No description provided for @prnOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get prnOpenSettings;

  /// No description provided for @mrTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get mrTitle;

  /// No description provided for @mrManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get mrManage;

  /// No description provided for @mrCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get mrCustomers;

  /// No description provided for @mrCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get mrCategories;

  /// No description provided for @mrSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get mrSalesHistory;

  /// No description provided for @mrReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get mrReturns;

  /// No description provided for @mrReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get mrReports;

  /// No description provided for @mrTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get mrTeam;

  /// No description provided for @mrBusinessGroup.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get mrBusinessGroup;

  /// No description provided for @mrBusinessRow.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get mrBusinessRow;

  /// No description provided for @mrBankak.
  ///
  /// In en, this message translates to:
  /// **'Bankak account'**
  String get mrBankak;

  /// No description provided for @mrBankakSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get mrBankakSetUp;

  /// No description provided for @mrThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get mrThisDevice;

  /// No description provided for @mrPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get mrPrinter;

  /// No description provided for @mrPrinterConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get mrPrinterConnected;

  /// No description provided for @mrPrinterNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get mrPrinterNotConnected;

  /// No description provided for @mrPrinterNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get mrPrinterNotSetUp;

  /// No description provided for @mrSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get mrSync;

  /// No description provided for @mrSyncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get mrSyncUpToDate;

  /// No description provided for @mrSyncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String mrSyncWaiting(int count);

  /// No description provided for @mrPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get mrPreferences;

  /// No description provided for @mrLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get mrLanguage;

  /// No description provided for @mrAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get mrAppearance;

  /// No description provided for @mrThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get mrThemeSystem;

  /// No description provided for @mrThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mrThemeLight;

  /// No description provided for @mrThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mrThemeDark;

  /// No description provided for @mrAnimations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get mrAnimations;

  /// No description provided for @mrAnimAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get mrAnimAuto;

  /// No description provided for @mrAnimAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Follows your device setting.'**
  String get mrAnimAutoHint;

  /// No description provided for @mrAnimOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get mrAnimOn;

  /// No description provided for @mrAnimOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mrAnimOff;

  /// No description provided for @mrSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get mrSecurity;

  /// No description provided for @mrFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get mrFaceId;

  /// No description provided for @mrFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get mrFingerprint;

  /// No description provided for @mrBiometricFoot.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {method} instead of typing your PIN.'**
  String mrBiometricFoot(String method);

  /// No description provided for @mrChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get mrChangePin;

  /// No description provided for @mrLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get mrLockNow;

  /// No description provided for @mrSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get mrSupport;

  /// No description provided for @mrContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get mrContactSupport;

  /// No description provided for @mrWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get mrWhatsApp;

  /// No description provided for @mrSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get mrSignOut;

  /// No description provided for @mrVersion.
  ///
  /// In en, this message translates to:
  /// **'AmanaPOS {version}'**
  String mrVersion(String version);

  /// No description provided for @mrPinOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off PIN on this device'**
  String get mrPinOff;

  /// No description provided for @mrPinOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off PIN?'**
  String get mrPinOffTitle;

  /// No description provided for @mrPinOffBody.
  ///
  /// In en, this message translates to:
  /// **'You will sign in with a code sent to your phone next time. Face ID turns off too.'**
  String get mrPinOffBody;

  /// No description provided for @mrPinOffAction.
  ///
  /// In en, this message translates to:
  /// **'Turn off PIN'**
  String get mrPinOffAction;

  /// No description provided for @mrPinOffDone.
  ///
  /// In en, this message translates to:
  /// **'PIN turned off.'**
  String get mrPinOffDone;

  /// No description provided for @mrSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of AmanaPOS?'**
  String get mrSignOutTitle;

  /// No description provided for @mrSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Sales that have not synced yet will be lost. Sync first if you can.'**
  String get mrSignOutBody;

  /// No description provided for @mrRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get mrRoleOwner;

  /// No description provided for @mrRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get mrRoleManager;

  /// No description provided for @mrRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get mrRoleCashier;

  /// No description provided for @prfTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get prfTitle;

  /// No description provided for @prfFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get prfFullName;

  /// No description provided for @prfEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get prfEmail;

  /// No description provided for @prfPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get prfPhone;

  /// No description provided for @prfRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get prfRole;

  /// No description provided for @prfPhoneFoot.
  ///
  /// In en, this message translates to:
  /// **'Your phone number is how you sign in, so it cannot be changed here.'**
  String get prfPhoneFoot;

  /// No description provided for @bkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bankak account'**
  String get bkTitle;

  /// No description provided for @bkAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get bkAccountNumber;

  /// No description provided for @bkAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get bkAccountName;

  /// No description provided for @bkFoot.
  ///
  /// In en, this message translates to:
  /// **'Customers who pay with Bankak are asked to send money to this account. The name comes from Bankak after you save.'**
  String get bkFoot;

  /// No description provided for @bkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove account'**
  String get bkRemove;

  /// No description provided for @bsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get bsTitle;

  /// No description provided for @bsName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get bsName;

  /// No description provided for @bsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get bsPhone;

  /// No description provided for @bsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bsEmail;

  /// No description provided for @bsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bsAddress;

  /// No description provided for @bsShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get bsShops;

  /// No description provided for @bsShopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shop} other{{count} shops}}'**
  String bsShopsCount(int count);

  /// No description provided for @bsTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get bsTax;

  /// No description provided for @bsChargeTax.
  ///
  /// In en, this message translates to:
  /// **'Charge tax on sales'**
  String get bsChargeTax;

  /// No description provided for @bsTaxName.
  ///
  /// In en, this message translates to:
  /// **'Tax name'**
  String get bsTaxName;

  /// No description provided for @bsTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get bsTaxRate;

  /// No description provided for @bsTaxInclusive.
  ///
  /// In en, this message translates to:
  /// **'Prices already include tax'**
  String get bsTaxInclusive;

  /// No description provided for @bsTaxFootOff.
  ///
  /// In en, this message translates to:
  /// **'Applied to every sale at all shops. Receipts show the tax line.'**
  String get bsTaxFootOff;

  /// No description provided for @bsTaxFootOn.
  ///
  /// In en, this message translates to:
  /// **'Off: tax is added on top of the price at checkout. On: the tax is taken out of the price you set.'**
  String get bsTaxFootOn;

  /// No description provided for @bsSaved.
  ///
  /// In en, this message translates to:
  /// **'Business saved.'**
  String get bsSaved;

  /// No description provided for @bsTaxRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate from 0 to 100.'**
  String get bsTaxRateInvalid;

  /// No description provided for @shInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get shInactive;

  /// No description provided for @shAdd.
  ///
  /// In en, this message translates to:
  /// **'Add shop'**
  String get shAdd;

  /// No description provided for @shNew.
  ///
  /// In en, this message translates to:
  /// **'New shop'**
  String get shNew;

  /// No description provided for @shEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get shEdit;

  /// No description provided for @shName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shName;

  /// No description provided for @shAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shAddress;

  /// No description provided for @shPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get shPhone;

  /// No description provided for @shOpenForSales.
  ///
  /// In en, this message translates to:
  /// **'Open for sales'**
  String get shOpenForSales;

  /// No description provided for @shOpenFoot.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide this shop from selling and from your cashiers. Its sales stay in history.'**
  String get shOpenFoot;

  /// No description provided for @shSwipeDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get shSwipeDeactivate;

  /// No description provided for @shSwipeReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get shSwipeReactivate;

  /// No description provided for @shSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to deactivate or reactivate.'**
  String get shSwipeHint;

  /// No description provided for @shDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String shDeactivateTitle(String name);

  /// No description provided for @shDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'Cashiers there will not be able to sell until you turn it back on. Its sales stay in history.'**
  String get shDeactivateBody;

  /// No description provided for @shDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get shDeactivateAction;

  /// No description provided for @shSaved.
  ///
  /// In en, this message translates to:
  /// **'Shop saved.'**
  String get shSaved;

  /// No description provided for @shAdded.
  ///
  /// In en, this message translates to:
  /// **'Shop added.'**
  String get shAdded;

  /// No description provided for @nfTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get nfTitle;

  /// No description provided for @nfMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get nfMarkAllRead;

  /// No description provided for @nfToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nfToday;

  /// No description provided for @nfEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get nfEarlier;

  /// No description provided for @nfEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get nfEmptyTitle;

  /// No description provided for @nfEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Subscription, stock and account news show up here.'**
  String get nfEmptyBody;

  /// No description provided for @nfErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get nfErrorTitle;

  /// No description provided for @nfErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get nfErrorBody;

  /// No description provided for @nfDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get nfDetailTitle;

  /// No description provided for @syTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syTitle;

  /// No description provided for @syWaitingLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{sale waiting} other{sales waiting}}'**
  String syWaitingLabel(int count);

  /// No description provided for @syAllDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get syAllDoneTitle;

  /// No description provided for @syAllDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Sales are sent as soon as you are online.'**
  String get syAllDoneBody;

  /// No description provided for @sySyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get sySyncNow;

  /// No description provided for @sySyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get sySyncing;

  /// No description provided for @syLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syLastSynced(String time);

  /// No description provided for @syNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syNeverSynced;

  /// No description provided for @syOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Sales are saved on this phone and send when you are back online.'**
  String get syOffline;

  /// No description provided for @syWaitingHeader.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syWaitingHeader;

  /// No description provided for @syPillFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syPillFailed;

  /// No description provided for @syPillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syPillWaiting;

  /// No description provided for @syItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String syItemsCount(int count);

  /// No description provided for @sySwipeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sySwipeRetry;

  /// No description provided for @sySwipeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sySwipeDelete;

  /// No description provided for @syFoot.
  ///
  /// In en, this message translates to:
  /// **'Failed sales stay here until you retry or delete them.'**
  String get syFoot;

  /// No description provided for @syDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this sale?'**
  String get syDeleteTitle;

  /// No description provided for @syDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It has not reached the server. Deleting removes it for good and the stock is not deducted.'**
  String get syDeleteBody;

  /// No description provided for @syDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete sale'**
  String get syDeleteAction;

  /// No description provided for @syFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this sale.'**
  String get syFailedFallback;

  /// No description provided for @syOxSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syOxSyncing;

  /// No description provided for @syOxServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get syOxServerUnreachable;

  /// No description provided for @syOxNeedsLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to sync'**
  String get syOxNeedsLogin;

  /// No description provided for @syOxAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get syOxAllSynced;

  /// No description provided for @syOxStatePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syOxStatePending;

  /// No description provided for @syOxStateRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get syOxStateRejected;

  /// No description provided for @syOxStateBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get syOxStateBlocked;

  /// No description provided for @syOxStateInflight.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get syOxStateInflight;

  /// No description provided for @syOxEntitySale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get syOxEntitySale;

  /// No description provided for @syOxEntityStock.
  ///
  /// In en, this message translates to:
  /// **'Stock change'**
  String get syOxEntityStock;

  /// No description provided for @syOxEntityInbound.
  ///
  /// In en, this message translates to:
  /// **'Stock received'**
  String get syOxEntityInbound;

  /// No description provided for @syOxEntityOther.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get syOxEntityOther;

  /// No description provided for @syOxOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'Other account'**
  String get syOxOtherAccount;

  /// No description provided for @syOxRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syOxRetry;

  /// No description provided for @syOxDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syOxDiscard;

  /// No description provided for @syOxErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this change.'**
  String get syOxErrorFallback;

  /// No description provided for @syOxDiscardSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this sale?'**
  String get syOxDiscardSaleTitle;

  /// No description provided for @syOxDiscardSaleBody.
  ///
  /// In en, this message translates to:
  /// **'The sale stays on this phone marked as rejected, but it will never be sent to the server.'**
  String get syOxDiscardSaleBody;

  /// No description provided for @syOxDiscardRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get syOxDiscardRowTitle;

  /// No description provided for @syOxDiscardRowBody.
  ///
  /// In en, this message translates to:
  /// **'It will not be sent to the server.'**
  String get syOxDiscardRowBody;

  /// No description provided for @syOxDiscardOtherAction.
  ///
  /// In en, this message translates to:
  /// **'Discard other account\'s changes'**
  String get syOxDiscardOtherAction;

  /// No description provided for @syOxDiscardOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard the other account\'s changes?'**
  String get syOxDiscardOtherTitle;

  /// No description provided for @syOxDiscardOtherBody.
  ///
  /// In en, this message translates to:
  /// **'Everything that account has not synced will be removed from this phone.'**
  String get syOxDiscardOtherBody;

  /// No description provided for @syOxLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsent changes'**
  String get syOxLogoutTitle;

  /// No description provided for @syOxLogoutReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get syOxLogoutReview;

  /// No description provided for @syOxWaitsBehind.
  ///
  /// In en, this message translates to:
  /// **'Waiting behind {label}'**
  String syOxWaitsBehind(String label);

  /// No description provided for @syOxUnsynced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 not synced} other{{count} not synced}}'**
  String syOxUnsynced(int count);

  /// No description provided for @syOxLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has} other{{count} changes have}} not reached the server. Review them to retry or discard before signing out.'**
  String syOxLogoutBody(int count);

  /// No description provided for @obCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your business'**
  String get obCreateTitle;

  /// No description provided for @obCreateBody.
  ///
  /// In en, this message translates to:
  /// **'This is the name customers see on receipts. You can change it later.'**
  String get obCreateBody;

  /// No description provided for @obCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create business'**
  String get obCreateAction;

  /// No description provided for @obCreateFoot.
  ///
  /// In en, this message translates to:
  /// **'Next you will add your first shop. Tax and team can wait.'**
  String get obCreateFoot;

  /// No description provided for @obExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended'**
  String get obExpiredTitle;

  /// No description provided for @obExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Renew to keep selling. Your products, sales and customers are safe.'**
  String get obExpiredBody;

  /// No description provided for @obExpiredAction.
  ///
  /// In en, this message translates to:
  /// **'Contact us to renew'**
  String get obExpiredAction;

  /// No description provided for @obExpiredSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get obExpiredSignOut;

  /// No description provided for @shpTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shpTitle;

  /// No description provided for @shpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shops yet'**
  String get shpEmptyTitle;

  /// No description provided for @shpEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A shop is where you sell. Add your first one to start.'**
  String get shpEmptyBody;

  /// No description provided for @posBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for barcode: {barcode}'**
  String posBarcodeNotFound(String barcode);

  /// No description provided for @ibReceived.
  ///
  /// In en, this message translates to:
  /// **'Stock received successfully'**
  String get ibReceived;

  /// No description provided for @ibQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued — will sync when online'**
  String get ibQueued;

  /// No description provided for @ibAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add at least one product'**
  String get ibAddProduct;

  /// No description provided for @ibSelectVendor.
  ///
  /// In en, this message translates to:
  /// **'Please select a vendor'**
  String get ibSelectVendor;

  /// No description provided for @ibNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products loaded'**
  String get ibNoProducts;

  /// No description provided for @ibNoVendors.
  ///
  /// In en, this message translates to:
  /// **'No vendors available'**
  String get ibNoVendors;

  /// No description provided for @ibInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Invoice or PO number'**
  String get ibInvoiceHint;

  /// No description provided for @ibSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, SKU, or barcode'**
  String get ibSearchHint;

  /// No description provided for @lsSwitchLocation.
  ///
  /// In en, this message translates to:
  /// **'Switch location'**
  String get lsSwitchLocation;

  /// No description provided for @exTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiry alerts'**
  String get exTitle;

  /// No description provided for @exLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expiry alerts.'**
  String get exLoadFailed;

  /// No description provided for @exEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expiry alerts'**
  String get exEmptyTitle;

  /// No description provided for @exEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'All products are within a safe expiry window.'**
  String get exEmptyBody;

  /// No description provided for @exToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get exToday;

  /// No description provided for @exExpiredAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Expired 1 day ago} other{Expired {count} days ago}}'**
  String exExpiredAgo(int count);

  /// No description provided for @exInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 day} other{In {count} days}}'**
  String exInDays(int count);

  /// No description provided for @poTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing offline mode'**
  String get poTitle;

  /// No description provided for @poDescOffline.
  ///
  /// In en, this message translates to:
  /// **'Internet is required only for the first setup. Please connect once so AmanaPOS can prepare your business for offline use.'**
  String get poDescOffline;

  /// No description provided for @poDescBootstrap.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open while we download your business data, products, categories, stock, and customers.'**
  String get poDescBootstrap;

  /// No description provided for @poDescAssets.
  ///
  /// In en, this message translates to:
  /// **'Your business data is ready. We are updating product and category assets in the background.'**
  String get poDescAssets;

  /// No description provided for @poDescFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while preparing offline mode.'**
  String get poDescFailure;

  /// No description provided for @poDescDefault.
  ///
  /// In en, this message translates to:
  /// **'Almost done. AmanaPOS is getting your workspace ready for poor internet and offline sales.'**
  String get poDescDefault;

  /// No description provided for @poStepBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business workspace'**
  String get poStepBusiness;

  /// No description provided for @poStepBusinessSub.
  ///
  /// In en, this message translates to:
  /// **'Business and shops'**
  String get poStepBusinessSub;

  /// No description provided for @poStepSales.
  ///
  /// In en, this message translates to:
  /// **'Sales data'**
  String get poStepSales;

  /// No description provided for @poStepSalesSub.
  ///
  /// In en, this message translates to:
  /// **'Products, categories, customers, and stock'**
  String get poStepSalesSub;

  /// No description provided for @poStepPending.
  ///
  /// In en, this message translates to:
  /// **'Pending sales'**
  String get poStepPending;

  /// No description provided for @poPendingNone.
  ///
  /// In en, this message translates to:
  /// **'No pending sales'**
  String get poPendingNone;

  /// No description provided for @poStepAssets.
  ///
  /// In en, this message translates to:
  /// **'Product assets'**
  String get poStepAssets;

  /// No description provided for @poStepAssetsSub.
  ///
  /// In en, this message translates to:
  /// **'Images and thumbnails'**
  String get poStepAssetsSub;

  /// No description provided for @poFooterNote.
  ///
  /// In en, this message translates to:
  /// **'This setup is required only once. After that, AmanaPOS can keep working during poor internet.'**
  String get poFooterNote;

  /// No description provided for @poTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get poTryAgain;

  /// No description provided for @poOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get poOnline;

  /// No description provided for @poOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get poOffline;

  /// No description provided for @poChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get poChecking;

  /// No description provided for @poUpdatingData.
  ///
  /// In en, this message translates to:
  /// **'Updating data'**
  String get poUpdatingData;

  /// No description provided for @poUpdatingAssets.
  ///
  /// In en, this message translates to:
  /// **'Updating assets'**
  String get poUpdatingAssets;

  /// No description provided for @poSyncingSales.
  ///
  /// In en, this message translates to:
  /// **'Syncing sales'**
  String get poSyncingSales;

  /// No description provided for @poOfflineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline ready'**
  String get poOfflineReady;

  /// No description provided for @poSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get poSyncFailed;

  /// No description provided for @poSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get poSynced;

  /// No description provided for @poReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get poReady;

  /// No description provided for @poPendingWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 sale waiting to sync} other{{count} sales waiting to sync}}'**
  String poPendingWaiting(int count);

  /// No description provided for @poPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String poPendingCount(int count);

  /// No description provided for @mrSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales & returns'**
  String get mrSalesReturns;

  /// No description provided for @mrSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mrSettings;

  /// No description provided for @mrTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get mrTheme;

  /// No description provided for @usExpiryNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Expiry tracking needs a connection'**
  String get usExpiryNeedsConnection;
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
