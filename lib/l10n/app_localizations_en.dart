// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navProducts => 'Products';

  @override
  String get navSell => 'Sell';

  @override
  String get navInventory => 'Stock';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCashiers => 'Cashiers';

  @override
  String get navMore => 'More';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get add => 'Add';

  @override
  String get retry => 'Retry';

  @override
  String get signOut => 'Sign out';

  @override
  String get noData => 'No data found';

  @override
  String get settingsSectionManage => 'MANAGE';

  @override
  String get settingsSectionAccount => 'ACCOUNT & SECURITY';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsCategoriesSubtitle => 'Organize products';

  @override
  String get settingsCashiers => 'Cashiers';

  @override
  String get settingsCashiersSubtitle => 'Staff access & shifts';

  @override
  String get settingsCustomers => 'Customers';

  @override
  String get settingsCustomersSubtitle => 'Profiles & loyalty';

  @override
  String get settingsReturns => 'Returns';

  @override
  String get settingsReturnsSubtitle => 'Process customer item returns';

  @override
  String get settingsSalesHistory => 'Sales history';

  @override
  String get settingsSalesHistorySubtitle =>
      'Browse and search all transactions';

  @override
  String get settingsSectionDevices => 'DEVICES';

  @override
  String get settingsAddPrinter => 'Add Printer';

  @override
  String get settingsPrinterSubtitle => 'Bluetooth receipt printer';

  @override
  String get printerScreenTitle => 'Receipt printer';

  @override
  String get printerDefaultLabel => 'Default printer';

  @override
  String get printerStatusNotConnected => 'Not connected';

  @override
  String get printerStatusConnecting => 'Connecting...';

  @override
  String get printerStatusConnected => 'Connected';

  @override
  String get printerStatusConnectionFailed => 'Connection failed';

  @override
  String get printerStatusPrinting => 'Printing...';

  @override
  String get printerStatusPrintSuccess => 'Printed successfully';

  @override
  String get printerStatusPrintFailed => 'Print failed';

  @override
  String get printerConnect => 'Connect';

  @override
  String get printerDisconnect => 'Disconnect';

  @override
  String get printerTestPrint => 'Test print';

  @override
  String get printerForget => 'Remove printer';

  @override
  String get printerForgetConfirmTitle => 'Remove this printer?';

  @override
  String get printerForgetConfirmBody => 'You can add it again at any time.';

  @override
  String get printerAvailable => 'Available printers';

  @override
  String get printerScan => 'Scan for printers';

  @override
  String get printerScanning => 'Scanning...';

  @override
  String get printerNoDevicesFound => 'No printers found';

  @override
  String get printerScanHint =>
      'Make sure the printer is turned on. On Android and Windows, pair it first in the system Bluetooth settings.';

  @override
  String get printerSavedAsDefault => 'Saved as default printer';

  @override
  String get printerErrorBluetoothOff =>
      'Bluetooth is off. Turn it on and try again.';

  @override
  String get printerErrorPermissionDenied =>
      'Bluetooth permission denied. Allow Bluetooth access in app settings.';

  @override
  String get printerErrorConnectionFailed =>
      'Could not connect to the printer. Check that it is turned on and in range.';

  @override
  String get printerErrorPrintFailed =>
      'Printing failed. Check the printer and try again.';

  @override
  String get printerErrorNoPrinterSaved =>
      'No printer set up. Add a printer in Settings.';

  @override
  String get printerErrorScanFailed =>
      'Could not search for printers. Try again.';

  @override
  String get printerNetworkSection => 'Network printer (LAN/WiFi)';

  @override
  String get printerAddNetwork => 'Add network printer';

  @override
  String get printerIpAddress => 'IP address';

  @override
  String get printerPort => 'Port';

  @override
  String get printerNameOptional => 'Name (optional)';

  @override
  String get printerInvalidIp => 'Enter a valid IP address.';

  @override
  String get printerNetworkHint =>
      'For printers connected with a LAN cable or WiFi, like the SAM4s GIANT-100. To find the printer\'s IP address, hold the FEED button while turning the printer on - it prints a self-test page showing the IP.';

  @override
  String get printerBleLabel => 'Bluetooth LE';

  @override
  String get printerNetworkLabel => 'LAN/WiFi printer';

  @override
  String get printReceipt => 'Print receipt';

  @override
  String get printerSetUp => 'Set up printer';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsBankakPayments => 'Bankak Payments';

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsPasswordSubtitle => 'Change your account password';

  @override
  String get settingsWhatsappSupport => 'WhatsApp Support';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get currentLanguageName => 'English';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get languagePickerSubtitle => 'Choose your preferred language.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishNative => 'English (EN)';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageArabicNative => 'العربية (AR)';

  @override
  String get profileUpdatedSuccess => 'Updated successfully';

  @override
  String get profileUpdateFailed => 'Failed to update';

  @override
  String get passwordUpdatedSuccess => 'Password updated';

  @override
  String get passwordUpdateFailed => 'Failed to update password';

  @override
  String get logoutConfirmTitle => 'Sign out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsAnimations => 'Animations';

  @override
  String get settingsAnimationsAutoSubtitle => 'Off on low-memory devices';

  @override
  String get animationsAuto => 'Automatic';

  @override
  String get animationsAlwaysOn => 'Always on';

  @override
  String get animationsAlwaysOff => 'Always off';

  @override
  String get loginWelcomeTitle => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Enter your mobile number to receive a 6-digit verification code.';

  @override
  String get loginMobileLabel => 'Mobile number';

  @override
  String get loginContinue => 'Continue';

  @override
  String get loginTermsPrefix => 'By continuing you agree to our ';

  @override
  String get loginTermsLink => 'Terms';

  @override
  String get loginTermsSeparator => ' & ';

  @override
  String get loginPrivacyLink => 'Privacy Policy';

  @override
  String get otpTitle => 'Verification code';

  @override
  String get otpSentPrefix => 'We sent a 6-digit code to\n';

  @override
  String get otpChange => 'Change';

  @override
  String get otpResendIn => 'Resend code in ';

  @override
  String get otpResendButton => 'Resend code';

  @override
  String get otpVerifyButton => 'Verify & continue';

  @override
  String get otpVerifiedButton => 'Verified';

  @override
  String get otpVerifiedSigningIn => 'Verified — signing you in…';

  @override
  String get themePickerTitle => 'Appearance';

  @override
  String get themePickerSubtitle => 'Choose how AmanaPOS looks on your device.';

  @override
  String get themeLightSubtitle => 'Clean bright interface. Always on.';

  @override
  String get themeDarkSubtitle => 'Easy on the eyes in low light.';

  @override
  String get themeSystemSubtitle =>
      'Follows your device setting automatically.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update your name and contact information.';

  @override
  String get fieldFullName => 'Full Name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get setPasswordTitle => 'Set Password';

  @override
  String get setPasswordSubtitle =>
      'Use a strong password to protect your AmanaPOS account.';

  @override
  String get fieldNewPassword => 'New Password';

  @override
  String get fieldConfirmPassword => 'Confirm Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get bankakAddTitle => 'Add Bankak Account';

  @override
  String get bankakChangeTitle => 'Change Bankak Account';

  @override
  String get bankakSheetSubtitle =>
      'Used when cashier selects Bankak as payment method in POS.';

  @override
  String get bankakInfoNote =>
      'AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.';

  @override
  String get bankakAccountNumber => 'Bankak Account Number';

  @override
  String get bankakSaveChanges => 'Save Changes';

  @override
  String get bankakAddAccount => 'Add Account';

  @override
  String get bankakRemove => 'Remove';

  @override
  String get bankakActive => 'Active';

  @override
  String get bankakNotSet => 'Not set';

  @override
  String get bankakUsedForLabel =>
      'Used for Bankak sales tracking and reports.';

  @override
  String get bankakPosNote =>
      'When cashier chooses Bankak in POS, AmanaPOS records the sale under this account.';

  @override
  String get bankakCardTitle => 'Bankak Payments';

  @override
  String get bankakChangeButton => 'Change Bankak Account';

  @override
  String get bankakAddButton => 'Add Bankak Account';

  @override
  String get bankakReadyTitle => 'Ready to accept Bankak sales';

  @override
  String get bankakReadySubtitle => 'Accept Bankak payments in POS';

  @override
  String get bankakAccountPrefix => 'Account ';

  @override
  String get bankakNoAccountAdded => 'No Bankak account added yet';

  @override
  String get bankakUpdateTitle => 'Update Bankak Account';

  @override
  String get posTodaySales => 'Today sales';

  @override
  String get posAllCategory => 'All';

  @override
  String get posSearchHint => 'Search · SKU · Barcode';

  @override
  String get posBankakNotSetup =>
      'Bankak account is not set up. Go to Settings and add your account number first.';

  @override
  String get posCashierNotAssigned =>
      'You are not assigned to a shop. Contact your manager.';

  @override
  String get posCharge => 'Charge';

  @override
  String get undo => 'Undo';

  @override
  String itemRemovedUndo(String name) {
    return '$name removed';
  }

  @override
  String get posNoShopFound => 'No shop found. Please refresh and try again.';

  @override
  String get posSaleCompleted => 'Sale completed successfully';

  @override
  String get posFailedSale => 'Failed to complete sale';

  @override
  String get posBankakRequired =>
      'Please add your Bankak account number in Settings.';

  @override
  String get posShopMismatch =>
      'You are not assigned to this shop. Contact your manager.';

  @override
  String posItemsUnavailable(String names) {
    return 'No longer available, removed from the cart: $names. It was merged, discarded or deleted. Review the cart and try again.';
  }

  @override
  String get productsManagement => 'Products Management';

  @override
  String get addProduct => 'Add Product';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsMessage =>
      'Add your first product to start building your catalog and begin selling.';

  @override
  String get productStatAll => 'Products';

  @override
  String get productStatActive => 'Active';

  @override
  String get productStatOutOfStock => 'Out';

  @override
  String get showList => 'Show list';

  @override
  String get showGrid => 'Show grid';

  @override
  String get newProduct => 'New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get addProductPhoto => 'Add product photo';

  @override
  String get tapToChangePhoto => 'Tap to change product image';

  @override
  String get fieldProductName => 'Product Name';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldCostPrice => 'Cost Price';

  @override
  String get fieldSku => 'SKU';

  @override
  String get fieldBarcode => 'Barcode';

  @override
  String get fieldMinStockLevel => 'Minimum Stock Level';

  @override
  String get fieldExpiryAlertDays => 'Expiry Alert (days)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get stockByShop => 'Stock by Shop';

  @override
  String get productPhotoSubtitle => 'Tap to change product image';

  @override
  String get inventoryAlertsTitle => 'Inventory Alerts';

  @override
  String get inventoryAlertsSubtitle =>
      'Set when AmanaPOS should warn you about low stock or expiring batches.';

  @override
  String get inventoryAlertsExpiryHint =>
      'You will be notified when a product batch is within the set number of days from its expiry date.';

  @override
  String get fieldExpiryAlert => 'Expiry Alert';

  @override
  String get menuCatalogTitle => 'Menu Catalog';

  @override
  String get productCatalogTitle => 'Product Catalog';

  @override
  String get menuCatalogSubtitle =>
      'Manage menu items, prices, and categories.';

  @override
  String get productCatalogSubtitle =>
      'Manage items, prices, categories, and stock availability.';

  @override
  String get newCategory => 'New Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get fieldCategoryName => 'Category Name';

  @override
  String get createCategory => 'Create Category';

  @override
  String get catStatTotal => 'Total';

  @override
  String get catStatActive => 'Active';

  @override
  String get catStatInactive => 'Inactive';

  @override
  String get catStatSub => 'Sub';

  @override
  String get catAppBarProducts => 'Products';

  @override
  String get catAppBarSub => 'Sub';

  @override
  String get catAppBarStatus => 'Status';

  @override
  String get noCategory => 'No category';

  @override
  String get expiredBatchOne => '1 batch expired';

  @override
  String expiredBatchMany(int count) {
    return '$count batches expired';
  }

  @override
  String expiringSoonCount(Object count) {
    return '$count expiring soon';
  }

  @override
  String expiringSoonMany(Object count) {
    return '$count expiring soon';
  }

  @override
  String expiringSoonBatchMany(int count) {
    return '$count expiring soon';
  }

  @override
  String get price => 'Price';

  @override
  String get category => 'Category';

  @override
  String get stock => 'Stock';

  @override
  String get oneDay => '1 day';

  @override
  String manyDays(int count) {
    return '$count days';
  }

  @override
  String get productAddedSuccessfully => 'Product added successfully';

  @override
  String get productNameHint => 'Pepsi 330ml';

  @override
  String get productDescriptionHint => 'Product description';

  @override
  String get generalCategory => 'General';

  @override
  String get autoCreated => 'Auto-created';

  @override
  String get selectBranch => 'Select branch';

  @override
  String get businessWorkspace => 'Business workspace';

  @override
  String get productDeletedSuccessfully => 'Product deleted successfully';

  @override
  String get deleteProductTitle => 'Delete Product?';

  @override
  String deleteProductMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get thisProduct => 'this product';

  @override
  String get all => 'All';

  @override
  String get productCategoriesTitle => 'Product Categories';

  @override
  String get productCategoriesSubtitle =>
      'Group products into simple sections for faster checkout and cleaner inventory.';

  @override
  String get activeCategories => 'Active Categories';

  @override
  String get inactiveCategories => 'Inactive Categories';

  @override
  String get categoriesWithSubCategories => 'Categories With Sub Categories';

  @override
  String get addCategory => 'Add Category';

  @override
  String get productNameRequired => 'Product name is required';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get invalidProduct => 'Invalid product';

  @override
  String get categoryMissing => 'Category is missing';

  @override
  String get productUpdatedSuccessfully => 'Product updated successfully';

  @override
  String get productPhoto => 'Product photo';

  @override
  String get tapToChangeProductImage => 'Tap to change product image';

  @override
  String get categoryLocked => 'Category locked';

  @override
  String get locked => 'Locked';

  @override
  String get allProducts => 'All Products';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String get product => 'Product';

  @override
  String get noCategoriesYetMessage =>
      'Create your first category to organize products.';

  @override
  String get noActiveCategories => 'No active categories';

  @override
  String get noActiveCategoriesMessage => 'No categories are currently active.';

  @override
  String get noInactiveCategories => 'No inactive categories';

  @override
  String get noInactiveCategoriesMessage =>
      'All categories are currently active.';

  @override
  String get noSubCategoriesFound => 'No sub categories found';

  @override
  String get noSubCategoriesFoundMessage =>
      'No categories have sub categories yet.';

  @override
  String get noDescriptionAdded => 'No description added';

  @override
  String subCategoryCount(int count) {
    return '$count sub';
  }

  @override
  String get categoryCreatedSuccessfully => 'Category created successfully';

  @override
  String get categoryNameHint => 'Beverages';

  @override
  String get categoryDescriptionHint =>
      'Drinks, juices, water, and hot beverages';

  @override
  String get createProductGroup => 'Create product group';

  @override
  String get createProductGroupMessage =>
      'Use categories to organize products and speed up checkout.';

  @override
  String get categoryTipsMessage =>
      'Keep category names short and clear, like Snacks, Drinks, Groceries, or Meals.';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryUpdatedSuccessfully => 'Category updated successfully';

  @override
  String get invalidCategory => 'Invalid category';

  @override
  String get categoryDescriptionShortHint => 'Drinks and beverages';

  @override
  String get categoryDefaultDescription =>
      'Organize products under this category for faster POS usage.';

  @override
  String get categoryNoProductsMessage =>
      'This category is ready. Add the first product here so it appears directly under this category.';

  @override
  String get back => 'Back';

  @override
  String get off => 'Off';

  @override
  String get offline => 'Offline';

  @override
  String get moreActions => 'More actions';

  @override
  String productCountLabel(int count) {
    return '$count products';
  }

  @override
  String get categoryDeletedSuccessfully => 'Category deleted successfully';

  @override
  String get deleteCategoryTitle => 'Delete Category?';

  @override
  String deleteCategoryMessage(String name) {
    return '\"$name\" will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get addCashier => 'Add Cashier';

  @override
  String get userStatTotal => 'Total';

  @override
  String get userStatActive => 'Active';

  @override
  String get userStatCashiers => 'Cashiers';

  @override
  String get userStatManagers => 'Managers';

  @override
  String get newUser => 'New User';

  @override
  String get editUser => 'Edit User';

  @override
  String get createStaffAccount => 'Create staff account';

  @override
  String get editStaffAccount => 'Edit staff account';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldRole => 'Role';

  @override
  String get fieldAssignedShop => 'Assigned Shop';

  @override
  String get createUser => 'Create User';

  @override
  String get userInfoTitle => 'Account Info';

  @override
  String get userInfoSubtitle => 'Basic cashier profile and access status.';

  @override
  String get userActivityTitle => 'Activity';

  @override
  String get userActivitySubtitle => 'Login and account creation details.';

  @override
  String get userDetailPhone => 'Phone';

  @override
  String get userDetailRole => 'Role';

  @override
  String get userDetailVerified => 'Verified';

  @override
  String get userDetailStatus => 'Status';

  @override
  String get userDetailLastLogin => 'Last login';

  @override
  String get userDetailJoined => 'Joined';

  @override
  String get deactivateUser => 'Deactivate User?';

  @override
  String get managerAccess => 'Manager access';

  @override
  String get shopRequired => 'Shop required';

  @override
  String get shopAssigned => 'Shop assigned';

  @override
  String get unassignedCashier => 'Unassigned cashier';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get customerStatTotal => 'Total';

  @override
  String get customerStatActive => 'Active';

  @override
  String get customerStatInactive => 'Inactive';

  @override
  String get customerStatCredit => 'Credit';

  @override
  String get customerStatPhone => 'Phone';

  @override
  String get fieldCustomerName => 'Customer Name';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldLoyaltyPoints => 'Loyalty Points';

  @override
  String get createCustomer => 'Create Customer';

  @override
  String get customerInactiveLabel => 'Inactive';

  @override
  String get customerSearchHint => 'Search customers, phone, email...';

  @override
  String get customerSalesPrefix => 'Sales';

  @override
  String get allUsers => 'All Users';

  @override
  String get activeUsers => 'Active Users';

  @override
  String get cashiers => 'Cashiers';

  @override
  String get managers => 'Managers';

  @override
  String get addUser => 'Add User';

  @override
  String get usersManagement => 'Users Management';

  @override
  String get usersManagementSubtitle =>
      'Manage staff accounts, roles, shop access, and POS permissions.';

  @override
  String get noUsersYet => 'No users yet';

  @override
  String get noUsersYetMessage =>
      'Add your first user so your team can start using the POS.';

  @override
  String get noActiveUsers => 'No active users';

  @override
  String get noActiveUsersMessage => 'No users are currently active.';

  @override
  String get noCashiersFound => 'No cashiers found';

  @override
  String get noCashiersFoundMessage =>
      'No cashier accounts are currently available.';

  @override
  String get noManagersFound => 'No managers found';

  @override
  String get noManagersFoundMessage =>
      'No manager accounts are currently available.';

  @override
  String get customers => 'Customers';

  @override
  String get customersSubtitle =>
      'Manage customer profiles, phone numbers, loyalty, and purchase history.';

  @override
  String get customerUpdatedSuccess => 'Customer updated successfully';

  @override
  String get customerUpdatedShort => 'Customer updated';

  @override
  String get customerCreated => 'Customer created';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noPhone => 'No phone';

  @override
  String get customersNotFound => 'No customers found';

  @override
  String get customersEmptyAll => 'No customers yet';

  @override
  String get customersEmptyActive => 'No active customers';

  @override
  String get customersEmptyInactive => 'No inactive customers';

  @override
  String get customersEmptyCredit => 'No credit customers';

  @override
  String get customersEmptyPhone => 'No customers with phone';

  @override
  String get customersEmptyAllMsg =>
      'Add your first customer to track loyalty and purchases.';

  @override
  String get customersEmptyActiveMsg => 'No customers are currently active.';

  @override
  String get customersEmptyInactiveMsg => 'All customers are currently active.';

  @override
  String get customersEmptyCreditMsg =>
      'No customers currently have credit or purchase balance.';

  @override
  String get customersEmptyPhoneMsg => 'No customers have phone numbers yet.';

  @override
  String get customersNoMatchTitle => 'No customers found';

  @override
  String customersNoMatchMsg(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get customersLoadFailed => 'Failed to load customers';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get editCustomerSubtitle =>
      'Update customer details and loyalty points.';

  @override
  String get addCustomerSubtitle =>
      'Create a customer profile for sales and loyalty.';

  @override
  String get hintCustomerAddress => 'Customer address';

  @override
  String get hintCustomerNotes => 'Any customer notes';

  @override
  String get deleteCustomerTitle => 'Delete Customer?';

  @override
  String deleteCustomerConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get invalidCustomer => 'Invalid customer';

  @override
  String loyaltyPointsSuffix(int points) {
    return '$points points';
  }

  @override
  String get returnFindSale => 'Find a sale to return';

  @override
  String get returnFindSaleSubtitle => 'Enter a receipt number or amount above';

  @override
  String get returnSearchFailed => 'Search failed';

  @override
  String get returnNoSalesFound => 'No sales found';

  @override
  String get returnNoSalesSubtitle =>
      'Try a different receipt number or amount';

  @override
  String get returnAll => 'Return all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get refCopied => 'Reference copied';

  @override
  String get shareReturnWhatsApp => 'Share return receipt via WhatsApp';

  @override
  String get salesHistoryTitle => 'Sales history';

  @override
  String get allSalesLoaded => 'All sales loaded';

  @override
  String get saleReceiptFailure => 'Failed to generate receipt PDF';

  @override
  String get returnItemsAction => 'Return items from this sale';

  @override
  String get salesCouldNotLoad => 'Could not load sales';

  @override
  String get saleComplete => 'Sale complete!';

  @override
  String get savedOffline => 'Saved offline';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get totalPaid => 'Total paid';

  @override
  String get shareViaWhatsApp => 'Share via WhatsApp';

  @override
  String get shareVia => 'Share via...';

  @override
  String get newSale => 'New sale';

  @override
  String get receiptCopied => 'Receipt number copied';

  @override
  String get saleSearchHint => 'Search receipt, amount, payment...';

  @override
  String get amanaPosLabel => 'AMANAPOS';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get posStatusOffline => 'Offline';

  @override
  String get posStatusSyncIssue => 'Sync issue';

  @override
  String get posStatusPending => 'Pending';

  @override
  String get posStatusSyncing => 'Syncing';

  @override
  String get posStatusSynced => 'Synced';

  @override
  String get clearLocalDataTitle => 'Clear local data?';

  @override
  String get localDataCleared => 'Local data cleared.';

  @override
  String get salesChipLabel => 'SALES';

  @override
  String get avgChipLabel => 'AVG';

  @override
  String viewPendingCount(int count) {
    return 'View $count pending';
  }

  @override
  String get loadingMore => 'Loading more';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get invExpiryExpired => 'Expired';

  @override
  String get invExpiryExpiringSoon => 'Expiring Soon';

  @override
  String get invHeroExport => 'Export';

  @override
  String get invHeroScan => 'Scan';

  @override
  String get invInventoryHealth => 'Inventory Health';

  @override
  String get invNeedsRestock => 'Needs Restock';

  @override
  String get invInboundThisMonth => 'Inbound This Month';

  @override
  String get invExpiringDays => 'Expiring ≤30 days';

  @override
  String get invQuickActionsTitle => 'Quick Actions';

  @override
  String get invReceive => 'Receive';

  @override
  String get invStockAction => 'Stock';

  @override
  String get invVendors => 'Vendors';

  @override
  String get invExpiry => 'Expiry';

  @override
  String get invHealthRingTitle => 'Health Ring';

  @override
  String get invHealthy => 'Healthy';

  @override
  String get invLow => 'Low';

  @override
  String get invOut => 'Out';

  @override
  String get invInboundVelocityTitle => 'Inbound Velocity';

  @override
  String get invExpiryTimelineTitle => 'Expiry Timeline';

  @override
  String get invRecentReceiptsTitle => 'Recent Receipts';

  @override
  String get invVendorBoardTitle => 'Vendor Board';

  @override
  String get invRestockQueueTitle => 'Restock Queue';

  @override
  String get invVendorSaved => 'Vendor saved';

  @override
  String get invVendorFailed => 'Failed to save vendor';

  @override
  String get invAddFirstVendor => 'Add your first vendor';

  @override
  String get invSelectVendor => 'Select vendor';

  @override
  String get invAddRow => 'Add Row';

  @override
  String get invMovementType => 'Movement Type';

  @override
  String get invFieldQuantity => 'Quantity';

  @override
  String get invFieldReference => 'Reference';

  @override
  String get invConfirmMovement => 'Confirm Movement';

  @override
  String get invFieldNewQuantity => 'New Quantity';

  @override
  String get invFieldNotes => 'Notes';

  @override
  String get invAdjustStock => 'Adjust Stock';

  @override
  String get invTransferTo => 'Transfer To';

  @override
  String get invQtyToTransfer => 'Quantity to Transfer';

  @override
  String get invTransferStock => 'Transfer Stock';

  @override
  String get invAddIn => 'Add In';

  @override
  String get invAdjust => 'Adjust';

  @override
  String get invTransfer => 'Transfer';

  @override
  String get invVendorDeactivate => 'Deactivate';

  @override
  String get bizManageLabel => 'MANAGE';

  @override
  String get bizQuickLinksLabel => 'QUICK LINKS';

  @override
  String get bizShopsTitle => 'Shops';

  @override
  String get live => 'LIVE';

  @override
  String get today => 'Today';

  @override
  String get bizActiveBranch => 'Active branch';

  @override
  String get bizActiveBranches => 'Active branches';

  @override
  String get bizProductsItem => 'Products item';

  @override
  String get bizProductsItems => 'Products items';

  @override
  String get bizUserSingular => 'User';

  @override
  String get bizUserPlural => 'Users';

  @override
  String get bizReportSubtitle => 'Browse and search all transactions';

  @override
  String get bizCreateMyBusiness => 'Create My Business';

  @override
  String get bizAddFirstShop => 'Add First Shop';

  @override
  String get bizFieldBusinessName => 'Business Name';

  @override
  String get bizFieldAddress => 'Address';

  @override
  String get bizFieldPhone => 'Phone';

  @override
  String get bizFieldEmail => 'Email';

  @override
  String get bizInfoTitle => 'Business Information';

  @override
  String get bizInfoSubtitle => 'Basic profile and contact details';

  @override
  String get bizDeactivateTitle => 'Deactivate Business?';

  @override
  String get bizFieldShopName => 'Shop Name';

  @override
  String get shopManagement => 'Shop Management';

  @override
  String get shopStatTotalShops => 'Total Shops';

  @override
  String get shopStatActive => 'Active';

  @override
  String get shopStatInactive => 'Inactive';

  @override
  String get bizStatusLabel => 'Status';

  @override
  String get bizAddressLabel => 'Address';

  @override
  String get bizPhoneLabel => 'Phone';

  @override
  String get bizEmailLabel => 'Email';

  @override
  String get bizShopsLabel => 'Shops';

  @override
  String get addShop => 'Add Shop';

  @override
  String get noShopsYet => 'No shops yet';

  @override
  String get firstShopMessage =>
      'Add your first shop location to start managing products, sales, and cashiers.';

  @override
  String get shop => 'Shop';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get newShop => 'New Shop';

  @override
  String get shopAddedSuccessfully => 'Shop added successfully';

  @override
  String get mainBranchHint => 'Main Branch';

  @override
  String get shopNameRequired => 'Shop name is required';

  @override
  String get nameMustBeAtLeast2Characters =>
      'Name must be at least 2 characters';

  @override
  String get optional => 'Optional';

  @override
  String get khartoumCentreHint => 'Khartoum Centre';

  @override
  String get enterValidPhoneNumber => 'Enter a valid phone number';

  @override
  String get editShop => 'Edit shop';

  @override
  String get status => 'Status';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get createStaffAccountMessage =>
      'Only cashier and manager accounts can be created here.';

  @override
  String get fullNameHint => 'Ali Hassan';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get invalidRoleSelected => 'Invalid role selected';

  @override
  String get assignCashierToShopRequired =>
      'Please assign this cashier to a shop.';

  @override
  String get userAddedSuccessfully => 'User added successfully';

  @override
  String autoAssignCashierToShop(String shopName) {
    return 'Will be assigned to $shopName automatically.';
  }

  @override
  String get selectShop => 'Select a shop';

  @override
  String get cashierShopRequiredMessage =>
      'Cashiers must be assigned to a shop to process sales.';

  @override
  String cashierAssignedToShop(String shopName) {
    return 'Cashier will be assigned to $shopName.';
  }

  @override
  String get thisShop => 'this shop';

  @override
  String get adminRoleHint =>
      'Full access — can manage everything including users and settings.';

  @override
  String get managerRoleHint =>
      'Can view reports, manage inventory and orders.';

  @override
  String get cashierRoleHint =>
      'Can process sales and manage the POS terminal.';

  @override
  String get editStaffAccountMessage =>
      'Only cashier and manager roles can be assigned from here.';

  @override
  String get adminRoleCannotBeAssigned =>
      'Admin role cannot be assigned from the app';

  @override
  String get invalidUserSelected => 'Invalid user selected';

  @override
  String get userUpdatedSuccessfully => 'User updated successfully';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get unassignedCashierMessage =>
      'This cashier is not assigned to any shop and cannot process sales.';

  @override
  String cashierAssignedToShopDetailed(String shopName) {
    return 'Assigned to $shopName. Cashier can process sales at this shop.';
  }

  @override
  String get managerAccessMessage =>
      'Managers are not assigned to a single shop. They can manage business operations based on their permissions.';

  @override
  String get userDeactivatedSuccessfully => 'User deactivated successfully';

  @override
  String deactivateUserMessage(String name) {
    return '\"$name\" will lose access immediately. You can reactivate them later.';
  }

  @override
  String get invalidUserId => 'Invalid user ID';

  @override
  String get thisUser => 'this user';

  @override
  String get noCashiersYet => 'No cashiers yet';

  @override
  String get noCashiersYetDescription =>
      'Add your first cashier so your team can start processing sales from the POS.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get never => 'Never';

  @override
  String get admin => 'Admin';

  @override
  String get manager => 'Manager';

  @override
  String get cashier => 'Cashier';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get managerAccessHint =>
      'Can manage inventory, reports and operations';

  @override
  String get cashierAccessHint => 'Can process sales and use POS terminal';

  @override
  String get adminAccessHint => 'Can manage business settings and staff access';

  @override
  String get staffAccountHint => 'Staff account';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String get failedToLoadProducts => 'Failed to load products';

  @override
  String get noProductsFound => 'No products found';

  @override
  String nothingMatchesQuery(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get tryAnotherCategoryOrAddProducts =>
      'Try another category or add products first.';

  @override
  String get payment => 'Payment';

  @override
  String get method => 'Method';

  @override
  String get bankak => 'Bankak';

  @override
  String get bankTransfer => 'Bank transfer';

  @override
  String get cash => 'Cash';

  @override
  String get payNow => 'Pay now';

  @override
  String bankakReadyAccount(String account) {
    return 'Bankak ready · Account $account';
  }

  @override
  String get bankakAccountSetupBanner =>
      'Bankak account is not set up. Tap to open settings.';

  @override
  String get bankakAccountNotSetUpMessage =>
      'Bankak account is not set up. Go to Settings and add your account number first.';

  @override
  String get cashierNotAssignedToShopMessage =>
      'You are not assigned to a shop. Contact your manager.';

  @override
  String get noShopFoundRefreshMessage =>
      'No shop found. Please refresh and try again.';

  @override
  String get clearCartQuestion => 'Clear cart?';

  @override
  String get clearCartDescription =>
      'This will remove all items from the current sale.';

  @override
  String get clear => 'Clear';

  @override
  String get reviewSale => 'Review sale';

  @override
  String get review => 'Review';

  @override
  String get reviewCart => 'Review cart';

  @override
  String get cart => 'Cart';

  @override
  String get completeSale => 'Complete sale';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Remove';

  @override
  String eachPrice(String price) {
    return '$price each';
  }

  @override
  String get failedToLoadSales => 'Failed to load sales';

  @override
  String get searchReceiptAmountPaymentHint =>
      'Search receipt, amount, payment...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get completed => 'Completed';

  @override
  String get returned => 'Returned';

  @override
  String get pending => 'Pending';

  @override
  String get allLoaded => 'All loaded';

  @override
  String get todaysSales => 'Today\'s';

  @override
  String get noMatchingSales => 'No matching sales';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get noSalesToday => 'No sales today';

  @override
  String get salesMadeTodayWillAppearHere =>
      'Sales made today will appear here';

  @override
  String get noPendingSales => 'No pending sales';

  @override
  String get allOfflineSalesSynced => 'All offline sales have been synced';

  @override
  String get noCompletedSales => 'No completed sales';

  @override
  String get noReturnedSales => 'No returned sales';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String get matchingSalesWillAppearHere => 'Matching sales will appear here';

  @override
  String get salesWillAppearHere =>
      'Sales will appear here once you complete your first checkout';

  @override
  String get card => 'Card';

  @override
  String get partiallyReturned => 'Partially returned';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get failed => 'Failed';

  @override
  String get unknown => 'Unknown';

  @override
  String todayWithTime(String time) {
    return 'Today $time';
  }

  @override
  String yesterdayWithTime(String time) {
    return 'Yesterday $time';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get allLoadedSales => 'All loaded sales';

  @override
  String get todaysSalesCount => 'Today\'s sales';

  @override
  String get completedSalesCount => 'Completed sales';

  @override
  String get returnedSalesCount => 'Returned sales';

  @override
  String get pendingSalesCount => 'Pending sales';

  @override
  String get allLoadedRevenue => 'All loaded revenue';

  @override
  String get todaysRevenue => 'Today\'s revenue';

  @override
  String get completedRevenue => 'Completed revenue';

  @override
  String get returnedRevenue => 'Returned revenue';

  @override
  String get pendingRevenue => 'Pending revenue';

  @override
  String get receiptNumberLabel => 'RECEIPT NUMBER';

  @override
  String get temporaryReferenceLabel => 'TEMPORARY REFERENCE';

  @override
  String get salePendingSyncDescription =>
      'This sale is pending sync. Returns and final receipt number are only available after the sale syncs to the server.';

  @override
  String get saleAlreadyRefunded => 'This sale has already been refunded.';

  @override
  String get preparingReceipt => 'Preparing receipt...';

  @override
  String get shareReceiptPdf => 'Share receipt PDF';

  @override
  String get receiptPdfShareHint =>
      'The receipt will be shared as a PDF file. Choose WhatsApp from the share options.';

  @override
  String get noItemDetailsAvailable => 'No item details available';

  @override
  String get wallet => 'Wallet';

  @override
  String get receipt => 'Receipt';

  @override
  String get amanaReceipt => 'AmanaPOS Receipt';

  @override
  String get salesReceipt => 'Sales Receipt';

  @override
  String get date => 'Date';

  @override
  String get item => 'Item';

  @override
  String get qty => 'Qty';

  @override
  String get amount => 'Amount';

  @override
  String get offlineSalePdfWarning =>
      'Offline sale - final server confirmation may still be pending.';

  @override
  String get thankYouForPurchase => 'Thank you for your purchase.';

  @override
  String get poweredByAmanaPOS => 'Powered by AmanaPOS';

  @override
  String get processReturn => 'Process return';

  @override
  String get returnSearchHint => 'Receipt number, amount...';

  @override
  String get returnSearchHelper => 'Receipt number, amount, or customer name';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String get returnPendingSyncCannotReturn =>
      'Pending sync — cannot return yet';

  @override
  String returnAlreadyProcessed(String status) {
    return 'Already $status';
  }

  @override
  String get originalSale => 'Original sale';

  @override
  String get tapItemsToSelect => 'Tap items to select';

  @override
  String get refundTotal => 'Refund total';

  @override
  String get items => 'items';

  @override
  String get selectItemsToReturn => 'Select items to return';

  @override
  String itemsSelected(Object selectedCount, Object totalCount) {
    return '$selectedCount of $totalCount items selected';
  }

  @override
  String get sold => 'sold';

  @override
  String get returnProcessed => 'Return processed!';

  @override
  String get stockRestored => 'Stock restored';

  @override
  String get receiptReady => 'Receipt ready to share';

  @override
  String get returnReference => 'Return reference';

  @override
  String get noReturnedItems => 'No returned items found';

  @override
  String get totalRefunded => 'Total refunded';

  @override
  String get returnReceipt => 'Return receipt';

  @override
  String get ref => 'Ref';

  @override
  String get refund => 'Refund';

  @override
  String get original => 'Original';

  @override
  String get cashRefund => 'Cash refund';

  @override
  String get settingsSynced => 'SYNCED';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonActive => 'Active';

  @override
  String get commonSetup => 'Setup';

  @override
  String get commonChange => 'Change';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get settingsBankakNotConfigured =>
      'Not configured — add Bankak to accept sales';

  @override
  String settingsBankakReady(String account) {
    return 'Account $account · ready for POS sales';
  }

  @override
  String get settingsProfileSubtitleFallback =>
      'Name, email and contact details';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String get settingsSignOutMessage =>
      'Make sure all your sales are synced before signing out. Offline sales that have not synced will be lost.';

  @override
  String get noBusinessesYet => 'No businesses yet';

  @override
  String get createFirstBusinessToGetStarted =>
      'Create your first business to get started.';

  @override
  String get addBusiness => 'Add Business';

  @override
  String get noStockEntriesYet => 'No stock entries yet';

  @override
  String get addStockToStartTracking =>
      'Add stock for your products to start tracking inventory.';

  @override
  String get noHealthyStockItems => 'No healthy stock items';

  @override
  String get noProductsInHealthyStockState =>
      'No products are currently in a healthy stock state.';

  @override
  String get noLowStockItems => 'No low stock items';

  @override
  String get noProductsLowOnStock =>
      'Everything looks good. No products are currently low on stock.';

  @override
  String get noOutOfStockItems => 'No out of stock items';

  @override
  String get noProductsOutOfStock =>
      'Great. No products are currently out of stock.';

  @override
  String get addStock => 'Add Stock';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get allCaughtUpNewNotificationsWillAppearHere =>
      'You\'re all caught up. New notifications will appear here.';

  @override
  String get salesViewTransactions => 'Transactions';

  @override
  String get salesViewReports => 'Reports & Statistics';

  @override
  String get customer => 'Customer';

  @override
  String get avgSale => 'Avg sale';

  @override
  String get refunds => 'Refunds';

  @override
  String get reportsComingSoon => 'Reports & Statistics are coming soon.';

  @override
  String get reportsRevenue => 'Revenue';

  @override
  String get reportsGross => 'Gross';

  @override
  String get reportsNet => 'Net';

  @override
  String get revenueAndSalesTrend => 'Revenue & Sales Trend';

  @override
  String get paymentMethodsTitle => 'Payment Methods';

  @override
  String get peakHoursTitle => 'Peak Hours';

  @override
  String get topProductsTitle => 'Top Products';

  @override
  String get topCategoriesTitle => 'Top Categories';

  @override
  String get dayOfWeekTitle => 'Day of Week';

  @override
  String get selectDateRange => 'Select date range';

  @override
  String get reportsNoSalesInRange => 'No sales in this period.';

  @override
  String get reportsLoadError => 'Failed to load report.';

  @override
  String get reportsRefresh => 'Refresh report';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get reportsNetSales => 'Net Sales';

  @override
  String get reportsSalesCount => 'Transactions';

  @override
  String get searchSalesHistoryHint => 'Search by receipt or customer';

  @override
  String get taxLabel => 'Tax';

  @override
  String taxWithRate(String taxName, String taxRate) {
    return 'Tax ($taxName $taxRate%)';
  }

  @override
  String taxWithRatePercent(String taxRate) {
    return 'Tax ($taxRate%)';
  }

  @override
  String totalInclTax(String taxName, String taxRate) {
    return 'Total (incl. $taxName $taxRate%)';
  }

  @override
  String get taxIncluded => 'Tax included';

  @override
  String get taxCollected => 'Tax Collected';

  @override
  String get taxDisabled => 'Tax disabled';

  @override
  String get pricesIncludeTax => 'Prices include tax';

  @override
  String get pricesExcludeTax => 'Prices exclude tax';

  @override
  String posRowInStock(String count) {
    return '$count in stock';
  }

  @override
  String posRowLowStock(String count) {
    return 'Low stock · $count';
  }

  @override
  String get posRowOutOfStock => 'Out of stock';

  @override
  String get cashReceived => 'Cash received';

  @override
  String get exactAmount => 'Exact';

  @override
  String get changeDue => 'Change due';

  @override
  String get posKeypad => 'Keypad';

  @override
  String get posItems => 'Items';

  @override
  String get posCustomAmount => 'Custom amount';

  @override
  String get posEnterAmount => 'Enter an amount';

  @override
  String get posAddToTicket => 'Add to ticket';

  @override
  String get posAddedToTicket => 'Added to ticket';

  @override
  String get posAddNote => 'Add a note';

  @override
  String get posNoteHint => 'What is it for?';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Enter your mobile number. We\'ll text you a 6-digit code.';

  @override
  String get signInInvalidNumber =>
      'Enter a valid mobile number, for example 912 345 678.';

  @override
  String get signInNeedAccess =>
      'Need access or want to register? Contact AmanaPOS support.';

  @override
  String get countryTitle => 'Country';

  @override
  String get countrySudan => 'Sudan';

  @override
  String get countryUae => 'UAE';

  @override
  String get codeTitle => 'Enter code';

  @override
  String codeSentTo(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get codeWrongNumber => 'Wrong number?';

  @override
  String codeResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get codeVerifying => 'Verifying…';

  @override
  String get codeVerified => 'Verified';

  @override
  String get pinCreateTitle => 'Create a PIN';

  @override
  String get pinCreateSubtitle => 'You\'ll use it to unlock AmanaPOS.';

  @override
  String get pinConfirmTitle => 'Confirm your PIN';

  @override
  String get pinConfirmSubtitle => 'Enter it once more.';

  @override
  String get pinEnterTitle => 'Enter your PIN';

  @override
  String pinWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get pinMismatch => 'PINs don\'t match. Start again.';

  @override
  String get pinWrong => 'Wrong PIN. Try again.';

  @override
  String get pinTaken => 'This PIN is already in use. Choose another.';

  @override
  String get pinUnavailable => 'Something went wrong. Try again.';

  @override
  String pinNotYou(String name) {
    return 'Not $name?';
  }

  @override
  String get pinUseDifferentAccount => 'Use a different account';

  @override
  String get pinForgot => 'Forgot your PIN?';

  @override
  String get pinLockedTitle => 'Too many attempts';

  @override
  String pinLockedSubtitle(String time) {
    return 'Try again in $time.';
  }

  @override
  String get pinCurrentTitle => 'Enter current PIN';

  @override
  String get pinCurrentSubtitle =>
      'Confirm it\'s you before changing your PIN.';

  @override
  String get pinNewTitle => 'New PIN';

  @override
  String get pinNewSubtitle => 'Choose a new 4-digit PIN.';

  @override
  String get pinConfirmNewTitle => 'Confirm new PIN';

  @override
  String get pinUpdated => 'PIN updated.';

  @override
  String get pinBiometricFace => 'Face ID';

  @override
  String get pinBiometricFingerprint => 'Fingerprint';

  @override
  String get pinBiometricGeneric => 'Biometrics';

  @override
  String get pinBiometricReason => 'Unlock AmanaPOS';

  @override
  String pinBiometricEnableTitle(String method) {
    return 'Use $method to unlock?';
  }

  @override
  String get pinBiometricEnableBody =>
      'Unlock AmanaPOS in a glance. Your PIN still works any time.';

  @override
  String pinBiometricEnable(String method) {
    return 'Turn on $method';
  }

  @override
  String get pinBiometricNotNow => 'Not now';

  @override
  String get menuLock => 'Lock';

  @override
  String get commonLoading => 'Loading';

  @override
  String get homeStatusLive => 'Live';

  @override
  String get homeStatusCached => 'Cached';

  @override
  String get homeStatusOffline => 'Offline sales included';

  @override
  String get homeGrossSales => 'Gross sales';

  @override
  String get homeStatSales => 'Sales';

  @override
  String get homeStatAverage => 'Average';

  @override
  String get homeStatRefunds => 'Refunds';

  @override
  String get homePayments => 'Payments';

  @override
  String get homeTopSellers => 'Top sellers';

  @override
  String get homeManage => 'Manage';

  @override
  String homeSoldQty(String qty) {
    return '$qty sold';
  }

  @override
  String homeShopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return '$_temp0';
  }

  @override
  String homeProductsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String homeUsersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users',
      one: '1 user',
    );
    return '$_temp0';
  }

  @override
  String get homeNoSalesTitle => 'No sales yet today';

  @override
  String get homeNoSalesBody =>
      'Sales you make will show up here, hour by hour.';

  @override
  String get homeStartSelling => 'Start selling';

  @override
  String get homePlanNone => 'No active subscription';

  @override
  String get homePlanContact => 'Contact support to activate your plan';

  @override
  String get homePlanFree => 'Free';

  @override
  String get homePlanPaid => 'Paid plan';

  @override
  String get homePlanInactive => 'Inactive';

  @override
  String get homePlanNoExpiry => 'No expiry';

  @override
  String get homePlanExpired => 'Expired';

  @override
  String homePlanDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String homePlanLimits(String shops, String products, String users) {
    return 'Shops $shops · Products $products · Users $users';
  }

  @override
  String get homePlanUnlimited => 'Unlimited';

  @override
  String get homePayCard => 'Card';

  @override
  String get homePayBankTransfer => 'Bank transfer';

  @override
  String get homePayWallet => 'Mobile wallet';

  @override
  String get homePayLoyalty => 'Loyalty points';

  @override
  String get homePayCredit => 'Credit';

  @override
  String get homePaySplit => 'Split';

  @override
  String get homePayOther => 'Other';

  @override
  String homePlanPriceMonthly(String price) {
    return '$price a month';
  }

  @override
  String homePlanPriceYearly(String price) {
    return '$price a year';
  }

  @override
  String get homeReportsHint => 'All transactions';

  @override
  String get pcSearchHint => 'Search name, SKU or barcode';

  @override
  String pcCount(String count) {
    return '$count products';
  }

  @override
  String get pcChipCategory => 'Category';

  @override
  String get pcChipLow => 'Low stock';

  @override
  String get pcChipOut => 'Out of stock';

  @override
  String pcInStock(String qty) {
    return '$qty in stock';
  }

  @override
  String pcLeft(String qty) {
    return '$qty left';
  }

  @override
  String get pcOutOfStock => 'Out of stock';

  @override
  String get pcSwipeStock => 'Stock';

  @override
  String get pcNoMatches => 'No matches';

  @override
  String get pcNoMatchesBody => 'Try another name, SKU or barcode.';

  @override
  String get pcErrorTitle => 'Could not load products';

  @override
  String get pcErrorBody => 'Check your connection and try again.';

  @override
  String get pcAllCategories => 'All categories';

  @override
  String get pcShowingSaved => 'Showing saved products';

  @override
  String pcDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get pcDeleteBody =>
      'This removes it from your catalog. Past sales keep their records.';

  @override
  String get pcDeleted => 'Product deleted';

  @override
  String get pcUpdateStock => 'Update stock';

  @override
  String get pcByShop => 'By shop';

  @override
  String get pcDetails => 'Details';

  @override
  String get pcUnitsShort => 'units';

  @override
  String get pcNoStockYet => 'No stock recorded yet';

  @override
  String get pcStockNotTracked => 'Stock is not tracked for this product';

  @override
  String get usAdd => 'Add';

  @override
  String get usRemove => 'Remove';

  @override
  String get usCount => 'Count';

  @override
  String get usMove => 'Move';

  @override
  String get usHintAdd => 'New stock arrived or was found.';

  @override
  String get usHintRemove => 'Damaged, lost or used up.';

  @override
  String get usHintCount =>
      'Type what you counted on the shelf. Stock is set to this number.';

  @override
  String get usHintMove => 'Send stock to another shop.';

  @override
  String get usFrom => 'From';

  @override
  String get usTo => 'To';

  @override
  String get usAfter => 'After';

  @override
  String get usExpiryDate => 'Expiry date';

  @override
  String get usNote => 'Note';

  @override
  String usSaveAdd(String qty) {
    return 'Add $qty';
  }

  @override
  String usSaveRemove(String qty) {
    return 'Remove $qty';
  }

  @override
  String usSaveCount(String qty) {
    return 'Set count to $qty';
  }

  @override
  String usSaveMove(String qty) {
    return 'Move $qty';
  }

  @override
  String get usSaved => 'Stock updated';

  @override
  String get usNotEnough => 'Not enough stock in this shop';

  @override
  String get usPickDifferentShop => 'Choose two different shops';

  @override
  String get usEnterQuantity => 'Enter a quantity';

  @override
  String get pfTrackStock => 'Track stock';

  @override
  String get pfTrackStockHint => 'Counts stock and warns when it runs low.';

  @override
  String get pfStartingStock => 'Starting stock';

  @override
  String get pfMoreDetails => 'More details';

  @override
  String get pfFewerDetails => 'Fewer details';

  @override
  String get pfLowStockAlert => 'Low stock alert';

  @override
  String get pfExpiryAlert => 'Expiry alert';

  @override
  String pfExpiryDays(String days) {
    return '$days days before';
  }

  @override
  String get pfAddPhoto => 'Add photo';

  @override
  String get pfChangePhoto => 'Change photo';

  @override
  String get pfDeleteProduct => 'Delete product';

  @override
  String get pfCategoryLockedNote =>
      'A product cannot move to another category.';

  @override
  String get pfCategoryNameHint => 'Category name';

  @override
  String get pfGeneralHint => 'Used when you pick nothing';

  @override
  String get pfEnterName => 'Enter a name';

  @override
  String get pfEnterPrice => 'Enter a price';

  @override
  String pfStockRowValue(String qty, String unit) {
    return '$qty $unit';
  }

  @override
  String get pfUnit => 'Unit';

  @override
  String get pfBarcode => 'Barcode';

  @override
  String get pfCostPrice => 'Cost price';

  @override
  String get pfSaving => 'Saving';

  @override
  String ctCountTitle(String count) {
    return '$count categories';
  }

  @override
  String get ctEmptyBody =>
      'Create a category to group products and find them faster.';

  @override
  String get ctDelete => 'Delete category';

  @override
  String get ctDeleteNote =>
      'Its products stay in your catalog without a category.';

  @override
  String ctInThis(String count) {
    return '$count products in this category';
  }

  @override
  String get ctNoProducts => 'No products in this category';

  @override
  String get ctNoProductsBody =>
      'Products you add here will show up in this category.';

  @override
  String get ctDescHint => 'What goes in this category';

  @override
  String get ctEnterName => 'Enter a category name';

  @override
  String get stReceive => 'Receive stock';

  @override
  String get stReceiveHint => 'Record a delivery';

  @override
  String get stAddStock => 'Add stock';

  @override
  String get stAttention => 'Needs attention';

  @override
  String get stExpiring => 'Expiring';

  @override
  String get stAllGood => 'Everything is in stock';

  @override
  String get stAllGoodBody =>
      'Low and out-of-stock products will show up here.';

  @override
  String get stVendors => 'Vendors';

  @override
  String get stReceipts => 'Receipts';

  @override
  String get stExpiryReport => 'Expiry report';

  @override
  String get stMore => 'More';

  @override
  String get fbCategoriesErrorTitle => 'Could not load categories';

  @override
  String get fbInvalidNumber => 'Enter a number, 0 or more';

  @override
  String get fbInvalidDays => 'Enter whole days, 1 or more';

  @override
  String get fbCategoriesTitle => 'Categories';

  @override
  String get pcAddProduct => 'Add product';

  @override
  String get pcEmptyBody => 'Add your first product to start selling it.';

  @override
  String get pfNewProduct => 'New product';

  @override
  String get pfEditProduct => 'Edit product';

  @override
  String get pfName => 'Name';

  @override
  String get pfNewCategory => 'New category';

  @override
  String get pfEditCategory => 'Edit category';

  @override
  String get sessionEndedSignInAgain =>
      'Your session ended. Sign in again to continue.';

  @override
  String get shUnit => 'SDG';

  @override
  String get shTitle => 'Sales history';

  @override
  String get shSearchHint => 'Search receipt, customer or phone';

  @override
  String shCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String get shChipDate => 'Date';

  @override
  String get shDateAny => 'Any date';

  @override
  String get shDateToday => 'Today';

  @override
  String get shDateYesterday => 'Yesterday';

  @override
  String get shDateLast7 => 'Last 7 days';

  @override
  String get shDateMonth => 'This month';

  @override
  String get shDateCustom => 'Custom range';

  @override
  String get shChipPayment => 'Payment';

  @override
  String get shPayAll => 'All payments';

  @override
  String get shPayCash => 'Cash';

  @override
  String get shPayBankak => 'Bankak';

  @override
  String get shPayCard => 'Card';

  @override
  String get shChipStatus => 'Status';

  @override
  String get shStatusAll => 'All statuses';

  @override
  String get shStatusCompleted => 'Completed';

  @override
  String get shStatusPartial => 'Partly returned';

  @override
  String get shStatusReturned => 'Returned';

  @override
  String get shStatusCancelled => 'Cancelled';

  @override
  String get shChipUnsynced => 'Not synced';

  @override
  String get shPillNotSynced => 'Not synced';

  @override
  String get shPillSyncFailed => 'Sync failed';

  @override
  String get shPillReturned => 'Returned';

  @override
  String get shPillPartial => 'Partly returned';

  @override
  String shItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get shWalkIn => 'Walk-in';

  @override
  String get shSwipeReturn => 'Return';

  @override
  String get shSwipeReceipt => 'Receipt';

  @override
  String get shEmptyTitle => 'No sales found';

  @override
  String get shEmptyBody => 'Try another receipt number, customer or filter.';

  @override
  String get shClearFilters => 'Clear filters';

  @override
  String get shErrorTitle => 'Could not load sales';

  @override
  String get shErrorBody => 'Check your connection and try again.';

  @override
  String get shTryAgain => 'Try again';

  @override
  String shWhen(String day, String time) {
    return '$day · $time';
  }

  @override
  String get shReceipt => 'Receipt';

  @override
  String get shDate => 'Date';

  @override
  String get shCashier => 'Cashier';

  @override
  String get shShop => 'Shop';

  @override
  String get shCustomer => 'Customer';

  @override
  String get shPayment => 'Payment';

  @override
  String get shNote => 'Note';

  @override
  String shItemsHeader(int count) {
    return 'Items · $count';
  }

  @override
  String get shSubtotal => 'Subtotal';

  @override
  String get shDiscount => 'Discount';

  @override
  String shTaxIncluded(String rate) {
    return 'Includes tax $rate%';
  }

  @override
  String get shTax => 'Tax';

  @override
  String get shTotal => 'Total';

  @override
  String get shReturnedTotal => 'Returned';

  @override
  String get shRefundPending => 'Refund pending sync';

  @override
  String get shRefundRejected => 'Refund rejected';

  @override
  String get shDataDriftTitle => 'Some numbers may be off';

  @override
  String get shDataDriftBody =>
      'This phone\'s totals do not match the server. Tap Sync now; if it stays, contact support.';

  @override
  String get shNet => 'Net';

  @override
  String get shReturnsHeader => 'Returns';

  @override
  String get shReturnItems => 'Return items';

  @override
  String get shShareReceipt => 'Share receipt';

  @override
  String get shCopied => 'Copied';

  @override
  String shLineReturned(String qty) {
    return '$qty returned';
  }

  @override
  String get shBannerPending =>
      'Waiting to sync. You can return this sale after it syncs.';

  @override
  String shBannerFailed(String reason) {
    return 'Could not sync this sale: $reason';
  }

  @override
  String get shBannerFailedNoReason => 'Could not sync this sale.';

  @override
  String shBankakAccount(String last4) {
    return 'Bankak ••• $last4';
  }

  @override
  String get shReceiptFailed => 'Could not prepare the receipt. Try again.';

  @override
  String get rtTitle => 'Return items';

  @override
  String get rtSelectAll => 'Select all';

  @override
  String get rtClear => 'Clear';

  @override
  String get rtItemsToReturn => 'Items to return';

  @override
  String rtSold(String qty) {
    return 'Sold $qty';
  }

  @override
  String rtSoldReturned(String qty, String returned) {
    return 'Sold $qty · Returned $returned';
  }

  @override
  String get rtQuantity => 'Quantity to return';

  @override
  String rtUpTo(String qty) {
    return 'Up to $qty';
  }

  @override
  String get rtReason => 'Reason';

  @override
  String get rtOptional => 'Optional';

  @override
  String get rtPayBack => 'Pay back via';

  @override
  String get rtFooter =>
      'Stock goes back on the shelf and the refund is counted in your reports.';

  @override
  String rtRefundButton(String amount) {
    return 'Refund $amount';
  }

  @override
  String get rtPickItems => 'Select items to return';

  @override
  String rtConfirmTitle(String amount) {
    return 'Refund $amount?';
  }

  @override
  String rtConfirmBodyCash(String amount) {
    return 'Stock is restored. Give the customer $amount in cash.';
  }

  @override
  String rtConfirmBodyOther(String amount, String method) {
    return 'Stock is restored. Send the customer $amount by $method.';
  }

  @override
  String get rtConfirmGo => 'Refund';

  @override
  String get rtDoneTitle => 'Return recorded';

  @override
  String get rtDoneBody => 'Stock is back on the shelf.';

  @override
  String get rtReference => 'Reference';

  @override
  String get rtShareWhatsApp => 'Share on WhatsApp';

  @override
  String get rtFailed => 'Could not record the return. Try again.';

  @override
  String get rtPickTitle => 'Return items';

  @override
  String get rtPickSubtitle => 'Find the sale to return from.';

  @override
  String get rtNotSynced => 'Not synced yet';

  @override
  String get rtAlreadyReturned => 'Already returned';

  @override
  String get rpTitle => 'Reports';

  @override
  String get rpToday => 'Today';

  @override
  String get rpYesterday => 'Yesterday';

  @override
  String get rpWeek => 'This week';

  @override
  String get rpMonth => 'This month';

  @override
  String get rpCustom => 'Custom';

  @override
  String get rpNetSales => 'Net sales';

  @override
  String rpFromSales(String count, String avg) {
    return 'From $count sales · average $avg';
  }

  @override
  String get rpGross => 'Gross';

  @override
  String get rpReturns => 'Returns';

  @override
  String get rpTax => 'Tax';

  @override
  String get rpTrendHour => 'Sales by hour';

  @override
  String get rpTrendDay => 'Sales by day';

  @override
  String get rpBusiest => 'Busiest';

  @override
  String get rpPayments => 'Payment methods';

  @override
  String get rpTopProducts => 'Top products';

  @override
  String get rpTopCategories => 'Top categories';

  @override
  String get rpPeakHours => 'Busiest hours';

  @override
  String get rpBusiestDays => 'Busiest days';

  @override
  String rpSold(String qty) {
    return '$qty sold';
  }

  @override
  String get rpFrom => 'From';

  @override
  String get rpTo => 'To';

  @override
  String get rpApply => 'Apply';

  @override
  String get rpCustomRange => 'Custom range';

  @override
  String get rpEmptyTitle => 'No sales in this period';

  @override
  String get rpEmptyBody => 'Pick another range to see your numbers.';

  @override
  String get rpErrorTitle => 'Could not load the report';

  @override
  String rpUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get rpOwnersOnly => 'Reports is for owners only.';

  @override
  String get homeSalesHistory => 'Sales history';

  @override
  String get homeSalesHint => 'Receipts and returns';

  @override
  String get homeReportsPerformance => 'Sales and performance';

  @override
  String get fmOptional => 'Optional';

  @override
  String get cuTitle => 'Customers';

  @override
  String cuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '$_temp0';
  }

  @override
  String cuCountInactive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers · inactive',
      one: '1 customer · inactive',
    );
    return '$_temp0';
  }

  @override
  String get cuSearch => 'Search name or phone';

  @override
  String get cuChipActive => 'Active';

  @override
  String get cuChipInactive => 'Inactive';

  @override
  String get cuEmptyTitle => 'No customers yet';

  @override
  String get cuEmptyBody =>
      'Save a customer once and attach them to a sale in a tap.';

  @override
  String get cuEmptyAction => 'Add customer';

  @override
  String get cuSwipeEdit => 'Edit';

  @override
  String get cuSwipeDeactivate => 'Deactivate';

  @override
  String get cuSwipeReactivate => 'Reactivate';

  @override
  String get cuInactiveTag => 'Inactive';

  @override
  String get cuEdit => 'Edit';

  @override
  String get cuCall => 'Call';

  @override
  String get cuWhatsApp => 'WhatsApp';

  @override
  String get cuEmailAction => 'Email';

  @override
  String get cuTotalPurchases => 'Total purchases';

  @override
  String get cuLoyalty => 'Loyalty points';

  @override
  String get cuSince => 'Customer since';

  @override
  String get cuContact => 'Contact';

  @override
  String get cuPhone => 'Phone';

  @override
  String get cuEmail => 'Email';

  @override
  String get cuAddress => 'Address';

  @override
  String get cuNotes => 'Notes';

  @override
  String get cuDeactivate => 'Deactivate customer';

  @override
  String get cuReactivate => 'Reactivate customer';

  @override
  String get cuInactiveBanner => 'Inactive. Hidden from search when selling.';

  @override
  String get cuNew => 'New customer';

  @override
  String get cuEditTitle => 'Edit customer';

  @override
  String get cuName => 'Name';

  @override
  String get cuMore => 'More details';

  @override
  String get cuLess => 'Fewer details';

  @override
  String get cuPhoneFoot =>
      'Used to find the customer and share receipts on WhatsApp.';

  @override
  String cuDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String cuDeactivateBody(String name) {
    return '$name will stop showing in the customer list. Past sales stay in history. You can reactivate any time.';
  }

  @override
  String get cuDeactivateConfirm => 'Deactivate';

  @override
  String get cuErrorTitle => 'Could not load customers';

  @override
  String get cuErrorBody => 'Check your connection and try again.';

  @override
  String get cuSaved => 'Customer saved';

  @override
  String get cuDeactivated => 'Customer deactivated';

  @override
  String get cuReactivated => 'Customer reactivated';

  @override
  String get tmTitle => 'Team';

  @override
  String tmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get tmManagers => 'Managers';

  @override
  String get tmCashiers => 'Cashiers';

  @override
  String get tmInvited => 'Invited';

  @override
  String get tmInactive => 'Inactive';

  @override
  String get tmNever => 'Never signed in';

  @override
  String get tmEmptyTitle => 'No team yet';

  @override
  String get tmEmptyBody =>
      'Add cashiers and managers. Each one signs in with their own phone.';

  @override
  String get tmEmptyAction => 'Add team member';

  @override
  String get tmSwipeDeactivate => 'Deactivate';

  @override
  String get tmRole => 'Role';

  @override
  String get tmBranch => 'Branch';

  @override
  String get tmLastSignIn => 'Last sign-in';

  @override
  String get tmJoined => 'Joined';

  @override
  String get tmCanSignIn => 'Can sign in';

  @override
  String get tmCanSignInFoot =>
      'Turn off to block sign-in right away. Their sales stay in history.';

  @override
  String get tmRoleManager => 'Manager';

  @override
  String get tmRoleCashier => 'Cashier';

  @override
  String get tmRoleManagerDesc =>
      'Sells, manages products and stock, sees reports. Cannot manage the team or billing.';

  @override
  String get tmRoleCashierDesc =>
      'Sells and processes returns. Sees only their own shift.';

  @override
  String get tmNew => 'New team member';

  @override
  String get tmFullName => 'Full name';

  @override
  String get tmPhone => 'Phone';

  @override
  String get tmSignFoot =>
      'They sign in with a code sent to this phone. There is no password or PIN to set.';

  @override
  String tmDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String tmDeactivateBody(String name) {
    return '$name will be signed out and can no longer sign in. Their sales stay in history.';
  }

  @override
  String get tmDeactivateConfirm => 'Deactivate';

  @override
  String get tmToday => 'Today';

  @override
  String get tmYesterday => 'Yesterday';

  @override
  String tmDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get tmErrorTitle => 'Could not load the team';

  @override
  String get tmSaved => 'Team member saved';

  @override
  String get tmUpdated => 'Team member updated';

  @override
  String get prnTestReceipt => 'Print a test receipt';

  @override
  String get prnForget => 'Forget printer';

  @override
  String get prnOther => 'Other printers';

  @override
  String get prnSearchNearby => 'Search nearby';

  @override
  String get prnSearching => 'Searching nearby…';

  @override
  String get prnAddByIp => 'Add by IP address';

  @override
  String get prnIpFoot =>
      'For network printers that listen on port 9100, like the SAM4s GIANT-100.';

  @override
  String get prnNearFoot =>
      'Printers paired in your phone settings or found over Bluetooth appear here.';

  @override
  String get prnNetworkTitle => 'Network printer';

  @override
  String get prnName => 'Name';

  @override
  String get prnNoPrinterTitle => 'No printer yet';

  @override
  String get prnNoPrinterBody =>
      'Search for a Bluetooth printer or add a network printer by its IP address.';

  @override
  String get prnBtOffTitle => 'Bluetooth is off for Amana';

  @override
  String get prnBtOffBody =>
      'Allow Bluetooth in Settings to find printers near you.';

  @override
  String get prnOpenSettings => 'Open Settings';

  @override
  String get mrTitle => 'More';

  @override
  String get mrManage => 'Manage';

  @override
  String get mrCustomers => 'Customers';

  @override
  String get mrCategories => 'Categories';

  @override
  String get mrSalesHistory => 'Sales history';

  @override
  String get mrReturns => 'Returns';

  @override
  String get mrReports => 'Reports';

  @override
  String get mrTeam => 'Team';

  @override
  String get mrBusinessGroup => 'Business';

  @override
  String get mrBusinessRow => 'Business';

  @override
  String get mrBankak => 'Bankak account';

  @override
  String get mrBankakSetUp => 'Set up';

  @override
  String get mrThisDevice => 'This device';

  @override
  String get mrPrinter => 'Receipt printer';

  @override
  String get mrPrinterConnected => 'Connected';

  @override
  String get mrPrinterNotConnected => 'Not connected';

  @override
  String get mrPrinterNotSetUp => 'Not set up';

  @override
  String get mrSync => 'Sync';

  @override
  String get mrSyncUpToDate => 'Up to date';

  @override
  String mrSyncWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get mrPreferences => 'Preferences';

  @override
  String get mrLanguage => 'Language';

  @override
  String get mrAppearance => 'Appearance';

  @override
  String get mrThemeSystem => 'System';

  @override
  String get mrThemeLight => 'Light';

  @override
  String get mrThemeDark => 'Dark';

  @override
  String get mrAnimations => 'Animations';

  @override
  String get mrAnimAuto => 'Automatic';

  @override
  String get mrAnimAutoHint => 'Follows your device setting.';

  @override
  String get mrAnimOn => 'Always on';

  @override
  String get mrAnimOff => 'Off';

  @override
  String get mrSecurity => 'Security';

  @override
  String get mrFaceId => 'Face ID';

  @override
  String get mrFingerprint => 'Fingerprint';

  @override
  String mrBiometricFoot(String method) {
    return 'Unlock with $method instead of typing your PIN.';
  }

  @override
  String get mrChangePin => 'Change PIN';

  @override
  String get mrLockNow => 'Lock now';

  @override
  String get mrSupport => 'Support';

  @override
  String get mrContactSupport => 'Contact support';

  @override
  String get mrWhatsApp => 'WhatsApp';

  @override
  String get mrSignOut => 'Sign out';

  @override
  String mrVersion(String version) {
    return 'AmanaPOS $version';
  }

  @override
  String get mrPinOff => 'Turn off PIN on this device';

  @override
  String get mrPinOffTitle => 'Turn off PIN?';

  @override
  String get mrPinOffBody =>
      'You will sign in with a code sent to your phone next time. Face ID turns off too.';

  @override
  String get mrPinOffAction => 'Turn off PIN';

  @override
  String get mrPinOffDone => 'PIN turned off.';

  @override
  String get mrSignOutTitle => 'Sign out of AmanaPOS?';

  @override
  String get mrSignOutBody =>
      'Sales that have not synced yet will be lost. Sync first if you can.';

  @override
  String get mrRoleOwner => 'Owner';

  @override
  String get mrRoleManager => 'Manager';

  @override
  String get mrRoleCashier => 'Cashier';

  @override
  String get prfTitle => 'Profile';

  @override
  String get prfFullName => 'Full name';

  @override
  String get prfEmail => 'Email';

  @override
  String get prfPhone => 'Phone';

  @override
  String get prfRole => 'Role';

  @override
  String get prfPhoneFoot =>
      'Your phone number is how you sign in, so it cannot be changed here.';

  @override
  String get bkTitle => 'Bankak account';

  @override
  String get bkAccountNumber => 'Account number';

  @override
  String get bkAccountName => 'Account name';

  @override
  String get bkFoot =>
      'Customers who pay with Bankak are asked to send money to this account. The name comes from Bankak after you save.';

  @override
  String get bkRemove => 'Remove account';

  @override
  String get bsTitle => 'Business';

  @override
  String get bsName => 'Business name';

  @override
  String get bsPhone => 'Phone';

  @override
  String get bsEmail => 'Email';

  @override
  String get bsAddress => 'Address';

  @override
  String get bsShops => 'Shops';

  @override
  String bsShopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shops',
      one: '1 shop',
    );
    return '$_temp0';
  }

  @override
  String get bsTax => 'Tax';

  @override
  String get bsChargeTax => 'Charge tax on sales';

  @override
  String get bsTaxName => 'Tax name';

  @override
  String get bsTaxRate => 'Rate';

  @override
  String get bsTaxInclusive => 'Prices already include tax';

  @override
  String get bsTaxFootOff =>
      'Applied to every sale at all shops. Receipts show the tax line.';

  @override
  String get bsTaxFootOn =>
      'Off: tax is added on top of the price at checkout. On: the tax is taken out of the price you set.';

  @override
  String get bsSaved => 'Business saved.';

  @override
  String get bsTaxRateInvalid => 'Enter a rate from 0 to 100.';

  @override
  String get shInactive => 'Inactive';

  @override
  String get shAdd => 'Add shop';

  @override
  String get shNew => 'New shop';

  @override
  String get shEdit => 'Edit shop';

  @override
  String get shName => 'Shop name';

  @override
  String get shAddress => 'Address';

  @override
  String get shPhone => 'Phone';

  @override
  String get shOpenForSales => 'Open for sales';

  @override
  String get shOpenFoot =>
      'Turn off to hide this shop from selling and from your cashiers. Its sales stay in history.';

  @override
  String get shSwipeDeactivate => 'Deactivate';

  @override
  String get shSwipeReactivate => 'Reactivate';

  @override
  String get shSwipeHint => 'Swipe to deactivate or reactivate.';

  @override
  String shDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get shDeactivateBody =>
      'Cashiers there will not be able to sell until you turn it back on. Its sales stay in history.';

  @override
  String get shDeactivateAction => 'Deactivate';

  @override
  String get shSaved => 'Shop saved.';

  @override
  String get shAdded => 'Shop added.';

  @override
  String get nfTitle => 'Notifications';

  @override
  String get nfMarkAllRead => 'Mark all read';

  @override
  String get nfToday => 'Today';

  @override
  String get nfEarlier => 'Earlier';

  @override
  String get nfEmptyTitle => 'You are all caught up';

  @override
  String get nfEmptyBody =>
      'Subscription, stock and account news show up here.';

  @override
  String get nfErrorTitle => 'Could not load notifications';

  @override
  String get nfErrorBody => 'Check your connection and try again.';

  @override
  String get nfDetailTitle => 'Notification';

  @override
  String get syTitle => 'Sync';

  @override
  String syWaitingLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sales waiting',
      one: 'sale waiting',
    );
    return '$_temp0';
  }

  @override
  String get syAllDoneTitle => 'Everything is synced';

  @override
  String get syAllDoneBody => 'Sales are sent as soon as you are online.';

  @override
  String get sySyncNow => 'Sync now';

  @override
  String get sySyncing => 'Syncing…';

  @override
  String syLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get syNeverSynced => 'Not synced yet';

  @override
  String get syOffline =>
      'You are offline. Sales are saved on this phone and send when you are back online.';

  @override
  String get syWaitingHeader => 'Waiting';

  @override
  String get syPillFailed => 'Failed';

  @override
  String get syPillWaiting => 'Waiting';

  @override
  String syItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get sySwipeRetry => 'Retry';

  @override
  String get sySwipeDelete => 'Delete';

  @override
  String get syFoot => 'Failed sales stay here until you retry or delete them.';

  @override
  String get syDeleteTitle => 'Delete this sale?';

  @override
  String get syDeleteBody =>
      'It has not reached the server. Deleting removes it for good and the stock is not deducted.';

  @override
  String get syDeleteAction => 'Delete sale';

  @override
  String get syFailedFallback => 'The server did not accept this sale.';

  @override
  String get syOxSyncing => 'Syncing';

  @override
  String get syOxServerUnreachable => 'Server unreachable';

  @override
  String get syOxNeedsLogin => 'Sign in again to sync';

  @override
  String get syOxAllSynced => 'All synced';

  @override
  String get syOxStatePending => 'Waiting';

  @override
  String get syOxStateRejected => 'Rejected';

  @override
  String get syOxStateBlocked => 'Blocked';

  @override
  String get syOxStateInflight => 'Sending';

  @override
  String get syOxEntitySale => 'Sale';

  @override
  String get syOxEntityStock => 'Stock change';

  @override
  String get syOxEntityInbound => 'Stock received';

  @override
  String get syOxEntityOther => 'Change';

  @override
  String get syOxOtherAccount => 'Other account';

  @override
  String get syOxRetry => 'Retry';

  @override
  String get syOxDiscard => 'Discard';

  @override
  String get syOxErrorFallback => 'The server did not accept this change.';

  @override
  String get syOxDiscardSaleTitle => 'Discard this sale?';

  @override
  String get syOxDiscardSaleBody =>
      'The sale stays on this phone marked as rejected, but it will never be sent to the server.';

  @override
  String get syOxDiscardRowTitle => 'Discard this change?';

  @override
  String get syOxDiscardRowBody => 'It will not be sent to the server.';

  @override
  String get syOxDiscardOtherAction => 'Discard other account\'s changes';

  @override
  String get syOxDiscardOtherTitle => 'Discard the other account\'s changes?';

  @override
  String get syOxDiscardOtherBody =>
      'Everything that account has not synced will be removed from this phone.';

  @override
  String get syOxLogoutTitle => 'Unsent changes';

  @override
  String get syOxLogoutReview => 'Review';

  @override
  String syOxWaitsBehind(String label) {
    return 'Waiting behind $label';
  }

  @override
  String syOxUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not synced',
      one: '1 not synced',
    );
    return '$_temp0';
  }

  @override
  String syOxLogoutBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes have',
      one: '1 change has',
    );
    return '$_temp0 not reached the server. Review them to retry or discard before signing out.';
  }

  @override
  String get obCreateTitle => 'Create your business';

  @override
  String get obCreateBody =>
      'This is the name customers see on receipts. You can change it later.';

  @override
  String get obCreateAction => 'Create business';

  @override
  String get obCreateFoot =>
      'Next you will add your first shop. Tax and team can wait.';

  @override
  String get obExpiredTitle => 'Your plan has ended';

  @override
  String get obExpiredBody =>
      'Renew to keep selling. Your products, sales and customers are safe.';

  @override
  String get obExpiredAction => 'Contact us to renew';

  @override
  String get obExpiredSignOut => 'Sign out';

  @override
  String get shpTitle => 'Shops';

  @override
  String get shpEmptyTitle => 'No shops yet';

  @override
  String get shpEmptyBody =>
      'A shop is where you sell. Add your first one to start.';

  @override
  String posBarcodeNotFound(String barcode) {
    return 'No product found for barcode: $barcode';
  }

  @override
  String get ibReceived => 'Stock received successfully';

  @override
  String get ibQueued => 'Queued — will sync when online';

  @override
  String get ibAddProduct => 'Add at least one product';

  @override
  String get ibSelectVendor => 'Please select a vendor';

  @override
  String get ibNoProducts => 'No products loaded';

  @override
  String get ibNoVendors => 'No vendors available';

  @override
  String get ibInvoiceHint => 'Invoice or PO number';

  @override
  String get ibSearchHint => 'Search by name, SKU, or barcode';

  @override
  String get lsSwitchLocation => 'Switch location';

  @override
  String get exTitle => 'Expiry alerts';

  @override
  String get exLoadFailed => 'Failed to load expiry alerts.';

  @override
  String get exEmptyTitle => 'No expiry alerts';

  @override
  String get exEmptyBody => 'All products are within a safe expiry window.';

  @override
  String get exToday => 'Expires today';

  @override
  String exExpiredAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expired $count days ago',
      one: 'Expired 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String exInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String get mrSalesReturns => 'Sales & returns';

  @override
  String get mrSettings => 'Settings';

  @override
  String get mrTheme => 'Theme';

  @override
  String get usExpiryNeedsConnection => 'Expiry tracking needs a connection';

  @override
  String get fsTitle => 'Setting up your business';

  @override
  String get fsSubRequired => 'Getting ready to download your business data.';

  @override
  String get fsSubRunning =>
      'Downloading your business data once so AmanaPOS can work offline.';

  @override
  String get fsOfflineTitle => 'You\'re offline';

  @override
  String get fsOfflineBody =>
      'Internet is required only for first setup. Connect once and setup continues where it stopped.';

  @override
  String get fsServerTitle => 'Server not ready';

  @override
  String get fsServerBody =>
      'The server can\'t run first setup yet. Try again later or contact support.';

  @override
  String get fsRetry => 'Try again';

  @override
  String fsStepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String fsRowsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records saved',
      one: '1 record saved',
    );
    return '$_temp0';
  }

  @override
  String get fsStepBusiness => 'Business and shops';

  @override
  String get fsStepCatalog => 'Products and categories';

  @override
  String get fsStepPeople => 'Customers, suppliers and team';

  @override
  String get fsStepStock => 'Stock and expiry dates';

  @override
  String get fsStepHistory => 'Recent sales and activity';

  @override
  String get fsResumeNote =>
      'If the app closes, setup continues where it stopped.';

  @override
  String get fsDoneTitle => 'All set';

  @override
  String get fsImagesDownloading =>
      'Images keep downloading in the background.';

  @override
  String get fsSignOut => 'Sign out / use another account';

  @override
  String get fsSubBlockedAccount => 'Setup can\'t continue with this sign-in.';

  @override
  String get fsTokenExpiredTitle => 'Session expired';

  @override
  String get fsTokenExpiredBody =>
      'Your sign-in has expired. Sign out and sign in again to continue setup.';

  @override
  String get fsAccountDisabledTitle => 'Account disabled';

  @override
  String get fsAccountDisabledBody =>
      'This account has been disabled. Contact the business owner or support, or sign in with another account.';

  @override
  String get fsDeviceRevokedTitle => 'Device removed';

  @override
  String get fsDeviceRevokedBody =>
      'This device was removed from the business. Sign out and sign in again, or contact the business owner.';

  @override
  String get loginRevokedPendingTitle => 'Unsynced data kept on this device';

  @override
  String loginRevokedPendingBody(int count) {
    return 'This device was signed out by the business, but $count unsynced items stay on it. Contact the business owner before clearing this device.';
  }

  @override
  String get fsNoSessionTitle => 'Not signed in';

  @override
  String get fsNoSessionBody =>
      'There is no active session. Sign out and sign in again to continue setup.';

  @override
  String get syOxRetryAll => 'Retry all rejected';

  @override
  String get syOxDiscardSending =>
      'This change is being sent right now, so it was not discarded. Check again in a moment.';

  @override
  String get syOxDiscardAlreadySynced =>
      'This change already reached the server, so it was not discarded.';

  @override
  String get syOxActionFailed =>
      'Could not update this change. Please try again.';

  @override
  String get authLogoutOffline =>
      'You are offline. Connect to the internet and sync all unsynced changes before signing out.';

  @override
  String authLogoutUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count unsynced changes',
      one: 'You have 1 unsynced change',
    );
    return '$_temp0 that have not been sent yet. Please sync or go online before signing out.';
  }

  @override
  String get authLogoutFailed =>
      'Logout failed. Please try again while connected to the internet.';

  @override
  String get syOxDiscardMaybeOnServer =>
      'This may already be on the server. Sync first, or discarding may lead to a duplicate if you ring it up again.';

  @override
  String get syOxDiscardOtherMaybeOnServer =>
      'Some of these changes may already be on the server. Sign in as that account and sync first, or discarding may lead to duplicates.';

  @override
  String get syOxSendNow => 'Send now';

  @override
  String get syOxDiscardOtherScope =>
      'This change belongs to another account. Use “Discard other account\'s changes” instead.';

  @override
  String get syOxEntityProduct => 'Product';

  @override
  String get syOxEntityCategory => 'Category';

  @override
  String get syOxEntityVendor => 'Vendor';

  @override
  String get syOxEditRetry => 'Edit and retry';

  @override
  String get syOxMerge => 'Merge into existing';

  @override
  String get syOxMergeTitle => 'Merge into the existing item?';

  @override
  String syOxMergeBody(String name) {
    return '“$name” already exists. This copy\'s details are dropped and everything recorded for it on this phone moves to the existing one.';
  }

  @override
  String syOxMergeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records will point to the existing item.',
      one: '1 record will point to the existing item.',
      zero: 'Nothing else changes.',
    );
    return '$_temp0';
  }

  @override
  String get syOxMergeExistingFallback => 'The existing item';

  @override
  String get syOxMergeRefused =>
      'This change can no longer be merged. Refresh and try again.';

  @override
  String get syOxEditNotSaved =>
      'Nothing was changed, so it was not sent again.';

  @override
  String get syOxEditGone => 'This item is no longer on this phone.';

  @override
  String get syOxDiscardCatalogCreateBody =>
      'This item and its opening stock will be removed from this phone. Nothing else waits on it.';

  @override
  String syOxDiscardBlockedByDependents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes wait on this item (sales, stock or products), so it cannot be discarded. Merge it into the existing item, or edit and retry.',
      one:
          '1 change waits on this item (a sale, stock or a product), so it cannot be discarded. Merge it into the existing item, or edit and retry.',
    );
    return '$_temp0';
  }

  @override
  String get syOxDiscardHasDependents =>
      'This item was not discarded: other changes (sales, stock or products) wait on it. Merge it into the existing item, or edit and retry.';

  @override
  String get syOxDiscardMayBeOnServerFailure =>
      'This item was not discarded: it may already be on the server. Tap Send now first; once it has synced, delete it from its own list.';

  @override
  String get syOxRetryMissingTitle => 'Send without its item?';

  @override
  String get syOxRetryMissingBody =>
      'A product, category or vendor this change refers to is no longer on this phone. If you send it, the server records it without that link: a sale keeps its money, but its product and stock are not updated.';

  @override
  String get syOxRetryMissingConfirm => 'Send anyway';

  @override
  String get syOxRetryMissingHint =>
      'Refers to an item that is no longer on this phone.';

  @override
  String get syOxStaleHint =>
      'Could not restore the server copy. It is replaced at the next sync.';

  @override
  String get syOxMergeStockAdded =>
      'Its opening stock and other stock changes on this phone are added to the existing item\'s stock.';

  @override
  String get syOxMergeEditsDropped =>
      'Its queued edits and its photo are dropped. The existing item keeps its own details and photo.';

  @override
  String get syOxMergeTargetInactive =>
      'The existing item is deleted. Merged sales and stock will belong to an item that the till does not show.';

  @override
  String get syOxDiscardCatalogEditBody =>
      'The item goes back to how it is on the server.';

  @override
  String get syOxUploadFailed => 'Image upload failed';

  @override
  String get invNoVendorsYet => 'No vendors yet';

  @override
  String get invAddVendor => 'Add Vendor';

  @override
  String get invEditVendor => 'Edit Vendor';

  @override
  String get invVendorNameLabel => 'Name *';

  @override
  String get userInvitePending => 'Invite pending';

  @override
  String get userSyncPending => 'Waiting to sync';

  @override
  String get userSyncFailed => 'Not applied';

  @override
  String get userConflictTitle => 'Change not applied';

  @override
  String userConflictBody(String name, String current, String yours) {
    return '$name was changed on another device. Now: $current. Your change: $yours.';
  }

  @override
  String get userConflictApplyMine => 'Apply mine again';

  @override
  String get userConflictDismiss => 'Dismiss';

  @override
  String get userPhoneExists =>
      'A team member with this phone number already exists.';

  @override
  String userChangeRefused(String reason) {
    return 'The server refused this change: $reason';
  }

  @override
  String get userChangeReactivate => 'Reactivate member';

  @override
  String get rcNumber => 'Receipt';

  @override
  String get rcDate => 'Date';

  @override
  String get rcCashier => 'Cashier';

  @override
  String get rcCustomer => 'Customer';

  @override
  String get rcSubtotal => 'Subtotal';

  @override
  String get rcDiscount => 'Discount';

  @override
  String get rcTax => 'Tax';

  @override
  String get rcTotal => 'Total';

  @override
  String get rcPaid => 'Paid';

  @override
  String get rcRefund => 'Refund';

  @override
  String get rcOwesNow => 'Customer owes';

  @override
  String get rcNotSynced => 'Saved on this terminal, not yet synced';

  @override
  String get rcThanks => 'Thank you for shopping with us';

  @override
  String get rcStatusCompleted => 'PAID';

  @override
  String get rcStatusPartialRefund => 'PARTIAL REFUND';

  @override
  String get rcStatusRefunded => 'REFUNDED';

  @override
  String get rcStatusCancelled => 'CANCELLED';

  @override
  String get rcStatusPending => 'PENDING';

  @override
  String get rcStatusFailed => 'FAILED';

  @override
  String get rcPayCash => 'Cash';

  @override
  String get rcPayBankak => 'Bankak';

  @override
  String get rcPayCard => 'Card';

  @override
  String get rcPaySplit => 'Split';

  @override
  String get rcPayCredit => 'On account';

  @override
  String get rcShareImage => 'Share as image';

  @override
  String get rcSharePdf => 'Share as PDF';

  @override
  String get rcPrint => 'Print';

  @override
  String get rcLoadFailed => 'Could not load the receipt';

  @override
  String rcTaxNamed(String name, String rate) {
    return 'Tax ($name $rate%)';
  }

  @override
  String rcTaxRated(String rate) {
    return 'Tax ($rate%)';
  }

  @override
  String rcTaxInclNamed(String name, String rate) {
    return 'Incl. $name $rate%';
  }

  @override
  String rcTaxInclRated(String rate) {
    return 'Tax incl. $rate%';
  }

  @override
  String rcLineDiscount(String amount) {
    return 'Discount −$amount';
  }

  @override
  String rcReturnedQty(String qty) {
    return 'Returned $qty';
  }

  @override
  String get sfTitle => 'Shifts';

  @override
  String sfChipOpen(String time) {
    return 'Shift $time';
  }

  @override
  String get sfChipNone => 'No shift';

  @override
  String get sfChipNeedsCount => 'Needs count';

  @override
  String get sfCurrent => 'Current shift';

  @override
  String get sfExpected => 'Cash that should be in the drawer';

  @override
  String get sfOpening => 'Opening cash';

  @override
  String get sfCashSales => 'Cash sales';

  @override
  String get sfDebtPayments => 'Debt payments (cash)';

  @override
  String get sfPayIns => 'Pay in';

  @override
  String get sfRefunds => 'Refunds and cancels (cash)';

  @override
  String get sfPayOuts => 'Pay out';

  @override
  String sfOther(String list) {
    return 'Also taken, not in the drawer: $list';
  }

  @override
  String sfOpenedBy(String time, String name) {
    return 'Open since $time · opened by $name';
  }

  @override
  String sfOpenedAuto(String time) {
    return 'Open since $time · started automatically';
  }

  @override
  String get sfSales => 'Sales';

  @override
  String get sfTotal => 'Total';

  @override
  String get sfDrawerOff =>
      'Cash drawer tracking is off. Counting and pay in/out are not used.';

  @override
  String get sfActOpen => 'Open shift';

  @override
  String get sfActClose => 'Close shift';

  @override
  String get sfActCount => 'Enter count';

  @override
  String get sfActPayIn => 'Pay in';

  @override
  String get sfActPayOut => 'Pay out';

  @override
  String get sfHistory => 'Earlier shifts';

  @override
  String get sfHistoryEmpty => 'No earlier shifts yet.';

  @override
  String get sfShowMore => 'Show more';

  @override
  String sfNeedsCountBanner(int count) {
    return 'Shifts waiting for a cash count: $count';
  }

  @override
  String get sfOffTitle => 'Shifts are off';

  @override
  String get sfOffHelp =>
      'The owner can turn shifts on in the dashboard. Sales work the same either way.';

  @override
  String get sfNoShiftTitle => 'No shift is open';

  @override
  String get sfNoShiftHelp =>
      'You can keep selling. Sales made now are not part of a shift.';

  @override
  String get sfWOpen => 'Open shift';

  @override
  String get sfWClose => 'Close shift';

  @override
  String get sfWCount => 'Enter the cash count';

  @override
  String get sfWPayIn => 'Pay in';

  @override
  String get sfWPayOut => 'Pay out';

  @override
  String get sfLOpening => 'Opening cash';

  @override
  String get sfLCounted => 'Counted cash';

  @override
  String get sfLExpected => 'Should be';

  @override
  String get sfLAmount => 'Amount';

  @override
  String get sfLReason => 'Reason';

  @override
  String get sfLNote => 'Note (optional)';

  @override
  String get sfCarryHint =>
      'Carried over from the last count. Change it if the drawer is different.';

  @override
  String get sfOverNote =>
      'This is more than the drawer should hold. You can continue.';

  @override
  String get sfDiffEven => 'Exact';

  @override
  String sfDiffShort(String amount) {
    return 'Short $amount';
  }

  @override
  String sfDiffOver(String amount) {
    return 'Over $amount';
  }

  @override
  String get sfOriginAuto => 'Auto';

  @override
  String get sfOriginManual => 'Manual';

  @override
  String get sfBtnSaveCount => 'Save count';

  @override
  String get sfDoneOpen => 'Shift opened';

  @override
  String get sfDoneClose => 'Shift closed';

  @override
  String get sfDoneCount => 'Count saved';

  @override
  String get sfDonePayIn => 'Pay in saved';

  @override
  String get sfDonePayOut => 'Pay out saved';

  @override
  String get sfErrNoSession => 'Sign in first.';

  @override
  String get sfErrNoShop => 'Pick a shop first.';

  @override
  String get sfErrNotAllowed =>
      'You are not allowed to do this. Ask the owner.';

  @override
  String get sfErrDisabled => 'Shifts are turned off.';

  @override
  String get sfErrDrawerOff => 'The cash drawer is turned off.';

  @override
  String get sfErrAlreadyOpen => 'A shift is already open.';

  @override
  String get sfErrNotOpen => 'No shift is open.';

  @override
  String get sfErrNotFound => 'That shift no longer exists.';

  @override
  String get sfErrNotCountable => 'This shift already has a count.';

  @override
  String get sfErrAmount => 'Enter an amount, like 250.00.';

  @override
  String get sfErrReason => 'Write a short reason.';

  @override
  String get sfErrSave => 'It could not be saved. Try again.';

  @override
  String get sfLoadFailed => 'Could not load the shifts.';

  @override
  String get sfTryAgain => 'Try again';
}
