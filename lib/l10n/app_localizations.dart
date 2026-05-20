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
  /// **'Inventory'**
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
