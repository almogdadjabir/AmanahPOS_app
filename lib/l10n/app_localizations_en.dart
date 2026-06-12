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
  String get navInventory => 'Inventory';

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
  String get posStatusOffline => 'OFFLINE';

  @override
  String get posStatusSyncIssue => 'SYNC ISSUE';

  @override
  String get posStatusPending => 'PENDING';

  @override
  String get posStatusSyncing => 'SYNCING';

  @override
  String get posStatusSynced => 'SYNCED';

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
}
