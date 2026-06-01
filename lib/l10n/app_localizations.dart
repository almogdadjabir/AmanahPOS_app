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
  /// **'OFFLINE'**
  String get posStatusOffline;

  /// No description provided for @posStatusSyncIssue.
  ///
  /// In en, this message translates to:
  /// **'SYNC ISSUE'**
  String get posStatusSyncIssue;

  /// No description provided for @posStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get posStatusPending;

  /// No description provided for @posStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'SYNCING'**
  String get posStatusSyncing;

  /// No description provided for @posStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
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
