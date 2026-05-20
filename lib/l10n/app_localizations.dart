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
