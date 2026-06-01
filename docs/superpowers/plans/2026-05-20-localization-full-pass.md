# Full-App Arabic Localization Pass — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate every remaining hardcoded user-facing string in AmanaPOS to ARB-backed `context.tr` calls, and create a `DirectionalIcon` helper that flips horizontal Solar arrows (altArrowLeft/Right) in RTL so Arabic navigation feels correct.

**Architecture:** Extend `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` in feature-sized batches, run `flutter gen-l10n` after each batch, then migrate the corresponding Dart files. A single `DirectionalIcon` widget in `lib/widgets/` handles all RTL arrow flipping. No new blocs, no new state — pure UI layer.

**Tech Stack:** Flutter ARB + `flutter gen-l10n`, `context.tr` extension already in `lib/common/localization/app_localizations_extension.dart`, Solar Icons package, `Directionality.of(context)` for RTL detection.

---

## What Is Already Done (Do NOT redo)

- `LocaleBloc`, `l10n.yaml`, `app_en/ar.arb` (69 keys), generated files
- `context.tr` extension, `LocaleBloc` in providers, `app.dart` delegates
- `LanguagePickerSheet`, `settings_screen.dart`, `bottom_nav.dart` fully migrated

---

## File Map

| Status | File | Task |
|--------|------|------|
| CREATE | `lib/widgets/directional_icon.dart` | 1 |
| MODIFY | `lib/l10n/app_en.arb` | 2–11 (incremental additions) |
| MODIFY | `lib/l10n/app_ar.arb` | 2–11 (incremental additions) |
| MODIFY | `lib/features/login/presentation/widgets/login_form.dart` | 2 |
| MODIFY | `lib/features/login/presentation/widgets/login_otp.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/widgets/theme_picker_sheet.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/widgets/edit_profile_sheet.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/widgets/set_password_sheet.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/widgets/edit_bankak_sheet.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/widgets/bankak_payment_card.dart` | 2 |
| MODIFY | `lib/features/settings/presentation/settings_screen.dart` (theme labels) | 2 |
| MODIFY | `lib/features/pos/presentation/pos_screen.dart` | 3 |
| MODIFY | `lib/features/pos/presentation/widgets/category_bar.dart` | 3 |
| MODIFY | `lib/features/pos/presentation/widgets/pos_search_section.dart` | 3 |
| MODIFY | `lib/features/products/presentation/product_screen.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/products_header_view.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/add_product_sheet.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/edit_product_sheet.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/delete_product_sheet.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/product_sheet_shell.dart` | 4 |
| MODIFY | `lib/features/products/presentation/product_detail_screen.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/product_barcode_field.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/product_inventory_alerts_section.dart` | 4 |
| MODIFY | `lib/features/products/presentation/widgets/product_details/product_actions_view.dart` | 4 |
| MODIFY | `lib/features/category/presentation/category_screen.dart` | 5 |
| MODIFY | `lib/features/category/presentation/widgets/categories_header.dart` | 5 |
| MODIFY | `lib/features/category/presentation/widgets/category_stats.dart` | 5 |
| MODIFY | `lib/features/category/presentation/widgets/add_category_sheet.dart` | 5 |
| MODIFY | `lib/features/category/presentation/widgets/edit_category_sheet.dart` | 5 |
| MODIFY | `lib/features/category/presentation/widgets/category_app_bar.dart` | 5 |
| MODIFY | `lib/features/users/presentation/users_screen.dart` | 6 |
| MODIFY | `lib/features/users/presentation/user_detail_screen.dart` | 6 |
| MODIFY | `lib/features/users/presentation/widgets/add_user_sheet.dart` | 6 |
| MODIFY | `lib/features/users/presentation/widgets/edit_user_sheet.dart` | 6 |
| MODIFY | `lib/features/users/presentation/widgets/deactivate_user_sheet.dart` | 6 |
| MODIFY | `lib/features/customers/presentation/customers_screen.dart` | 7 |
| MODIFY | `lib/features/customers/presentation/widgets/customer_form_sheet.dart` | 7 |
| MODIFY | `lib/features/customers/presentation/widgets/delete_customer_sheet.dart` | 7 |
| MODIFY | `lib/features/returns/presentation/returns_screen.dart` | 8 |
| MODIFY | `lib/features/returns/presentation/widgets/returns_search_view.dart` | 8 |
| MODIFY | `lib/features/returns/presentation/widgets/return_success_sheet.dart` | 8 |
| MODIFY | `lib/features/sales_history/presentation/sales_history_screen.dart` | 8 |
| MODIFY | `lib/features/sales_history/presentation/widgets/sale_app_bar.dart` | 8 |
| MODIFY | `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart` | 8 |
| MODIFY | `lib/features/sales_history/presentation/widgets/sale_footer.dart` | 8 |
| MODIFY | `lib/features/sales_history/presentation/widgets/sale_error_view.dart` | 8 |
| MODIFY | `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart` | 8 |
| MODIFY | `lib/features/notification/presentation/notifications_screen.dart` | 9 |
| MODIFY | `lib/features/main_screen/presentation/widgets/pos_app_bar.dart` | 9 |
| MODIFY | `lib/features/main_screen/presentation/widgets/more_footer.dart` | 9 |
| MODIFY | `lib/features/main_screen/presentation/widgets/today_cards.dart` | 9 |
| MODIFY | `lib/features/inventory/presentation/expiry_alerts_screen.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/premium_hero_header.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/quick_actions_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/health_ring_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/inbound_velocity_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/expiry_timeline_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/recent_receipts_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/vendor_board_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/widgets/restock_queue_card.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart` | 10 |
| MODIFY | `lib/features/inventory/presentation/widgets/stock_action_sheet.dart` | 10 |
| MODIFY | `lib/features/business/presentation/business_detail_screen.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/add_business_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/edit_business_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/deactivate_business_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/info_section.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/shop/add_shop_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/widgets/shop/shop_quick_stats.dart` | 11 |
| MODIFY | `lib/features/business/presentation/fancy_business_bottom_sheet.dart` | 11 |
| MODIFY | `lib/features/business/presentation/shop_management_screen.dart` | 11 |
| RTL PASS | All files with `SolarIconsOutline.altArrowLeft/Right` (14 files) | 12 |

---

## ARB Key Reference (all new keys, grouped by task)

### Keys added in Task 2 (Login + Settings sheets)

**English additions to `lib/l10n/app_en.arb`:**
```json
"loginWelcomeTitle": "Welcome back",
"loginSubtitle": "Enter your mobile number to receive a 6-digit verification code.",
"loginMobileLabel": "Mobile number",
"loginContinue": "Continue",
"loginTermsPrefix": "By continuing you agree to our ",
"loginTermsLink": "Terms",
"loginTermsSeparator": " & ",
"loginPrivacyLink": "Privacy Policy",

"otpTitle": "Verification code",
"otpSentPrefix": "We sent a 6-digit code to\n",
"otpChange": "Change",
"otpResendIn": "Resend code in ",
"otpResendButton": "Resend code",
"otpVerifyButton": "Verify & continue",
"otpVerifiedButton": "Verified",
"otpVerifiedSigningIn": "Verified — signing you in…",

"themePickerTitle": "Appearance",
"themePickerSubtitle": "Choose how AmanaPOS looks on your device.",
"themeLightSubtitle": "Clean bright interface. Always on.",
"themeDarkSubtitle": "Easy on the eyes in low light.",
"themeSystemSubtitle": "Follows your device setting automatically.",

"editProfileTitle": "Edit Profile",
"editProfileSubtitle": "Update your name and contact information.",
"fieldFullName": "Full Name",
"fieldEmail": "Email",
"saveProfile": "Save Profile",

"setPasswordTitle": "Set Password",
"setPasswordSubtitle": "Use a strong password to protect your AmanaPOS account.",
"fieldNewPassword": "New Password",
"fieldConfirmPassword": "Confirm Password",
"updatePassword": "Update Password",

"bankakAddTitle": "Add Bankak Account",
"bankakChangeTitle": "Change Bankak Account",
"bankakSheetSubtitle": "Used when cashier selects Bankak as payment method in POS.",
"bankakInfoNote": "AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.",
"bankakAccountNumber": "Bankak Account Number",
"bankakSaveChanges": "Save Changes",
"bankakAddAccount": "Add Account",
"bankakRemove": "Remove",
"bankakActive": "Active",
"bankakNotSet": "Not set",
"bankakUsedForLabel": "Used for Bankak sales tracking and reports.",
"bankakPosNote": "When cashier chooses Bankak in POS, AmanaPOS records the sale under this account.",
"bankakCardTitle": "Bankak Payments",
"bankakChangeButton": "Change Bankak Account",
"bankakAddButton": "Add Bankak Account"
```

**Arabic additions to `lib/l10n/app_ar.arb`:**
```json
"loginWelcomeTitle": "مرحباً بعودتك",
"loginSubtitle": "أدخل رقم جوالك لاستلام رمز التحقق المكون من 6 أرقام.",
"loginMobileLabel": "رقم الجوال",
"loginContinue": "متابعة",
"loginTermsPrefix": "بالمتابعة، فإنك توافق على ",
"loginTermsLink": "الشروط",
"loginTermsSeparator": " و ",
"loginPrivacyLink": "سياسة الخصوصية",

"otpTitle": "رمز التحقق",
"otpSentPrefix": "أرسلنا رمزاً من 6 أرقام إلى\n",
"otpChange": "تغيير",
"otpResendIn": "إعادة الإرسال بعد ",
"otpResendButton": "إعادة إرسال الرمز",
"otpVerifyButton": "تحقق وتابع",
"otpVerifiedButton": "تم التحقق",
"otpVerifiedSigningIn": "تم التحقق — جارٍ تسجيل الدخول...",

"themePickerTitle": "المظهر",
"themePickerSubtitle": "اختر مظهر أمانة على جهازك.",
"themeLightSubtitle": "واجهة مضيئة ونظيفة. دائماً مفعّلة.",
"themeDarkSubtitle": "مريحة للعيون في الضوء الخافت.",
"themeSystemSubtitle": "تتبع إعداد جهازك تلقائياً.",

"editProfileTitle": "تعديل الملف الشخصي",
"editProfileSubtitle": "تحديث اسمك ومعلومات الاتصال.",
"fieldFullName": "الاسم الكامل",
"fieldEmail": "البريد الإلكتروني",
"saveProfile": "حفظ الملف الشخصي",

"setPasswordTitle": "تعيين كلمة المرور",
"setPasswordSubtitle": "استخدم كلمة مرور قوية لحماية حسابك في أمانة.",
"fieldNewPassword": "كلمة المرور الجديدة",
"fieldConfirmPassword": "تأكيد كلمة المرور",
"updatePassword": "تحديث كلمة المرور",

"bankakAddTitle": "إضافة حساب بنكك",
"bankakChangeTitle": "تغيير حساب بنكك",
"bankakSheetSubtitle": "يُستخدم عندما يختار الكاشير بنكك كطريقة دفع في نقطة البيع.",
"bankakInfoNote": "ستسجّل أمانة مبيعات بنكك تحت هذا الحساب للتقارير. العميل يدفع عبر تطبيق بنكك.",
"bankakAccountNumber": "رقم حساب بنكك",
"bankakSaveChanges": "حفظ التغييرات",
"bankakAddAccount": "إضافة حساب",
"bankakRemove": "إزالة",
"bankakActive": "نشط",
"bankakNotSet": "غير محدد",
"bankakUsedForLabel": "يُستخدم لتتبع مبيعات بنكك والتقارير.",
"bankakPosNote": "عندما يختار الكاشير بنكك في نقطة البيع، تسجّل أمانة البيعة تحت هذا الحساب.",
"bankakCardTitle": "مدفوعات بنكك",
"bankakChangeButton": "تغيير حساب بنكك",
"bankakAddButton": "إضافة حساب بنكك"
```

### Keys added in Task 3 (POS)

**English:**
```json
"posTodaySales": "Today sales",
"posAllCategory": "All",
"posSearchHint": "Search · SKU · Barcode",
"posBankakNotSetup": "Bankak account is not set up. Go to Settings and add your account number first.",
"posCashierNotAssigned": "You are not assigned to a shop. Contact your manager.",
"posNoShopFound": "No shop found. Please refresh and try again.",
"posSaleCompleted": "Sale completed successfully",
"posFailedSale": "Failed to complete sale",
"posBankakRequired": "Please add your Bankak account number in Settings.",
"posShopMismatch": "You are not assigned to this shop. Contact your manager."
```

**Arabic:**
```json
"posTodaySales": "مبيعات اليوم",
"posAllCategory": "الكل",
"posSearchHint": "بحث · الرمز التعريفي · الباركود",
"posBankakNotSetup": "لم يُعدَّ حساب بنكك. اذهب إلى الإعدادات وأضف رقم حسابك أولاً.",
"posCashierNotAssigned": "لم تُعيَّن لمتجر. تواصل مع مديرك.",
"posNoShopFound": "لم يتم العثور على متجر. حدّث الصفحة وحاول مجدداً.",
"posSaleCompleted": "تمت البيعة بنجاح",
"posFailedSale": "فشل إتمام البيعة",
"posBankakRequired": "يرجى إضافة رقم حساب بنكك في الإعدادات.",
"posShopMismatch": "لست مُعيَّناً لهذا المتجر. تواصل مع مديرك."
```

### Keys added in Task 4 (Products)

**English:**
```json
"productsManagement": "Products Management",
"addProduct": "Add Product",
"noProductsYet": "No products yet",
"noProductsMessage": "Add your first product to start building your catalog and begin selling.",
"productStatAll": "Products",
"productStatActive": "Active",
"productStatOutOfStock": "Out",
"showList": "Show list",
"showGrid": "Show grid",
"newProduct": "New Product",
"editProduct": "Edit Product",
"addProductPhoto": "Add product photo",
"tapToChangePhoto": "Tap to change product image",
"fieldProductName": "Product Name",
"fieldCategory": "Category",
"fieldUnit": "Unit",
"fieldDescription": "Description",
"fieldPrice": "Price",
"fieldCostPrice": "Cost Price",
"fieldSku": "SKU",
"fieldBarcode": "Barcode",
"fieldMinStockLevel": "Minimum Stock Level",
"fieldExpiryAlertDays": "Expiry Alert (days)",
"saveChanges": "Save Changes",
"stockByShop": "Stock by Shop",
"productPhotoSubtitle": "Tap to change product image"
```

**Arabic:**
```json
"productsManagement": "إدارة المنتجات",
"addProduct": "إضافة منتج",
"noProductsYet": "لا توجد منتجات بعد",
"noProductsMessage": "أضف منتجك الأول لبناء الكتالوج والبدء بالبيع.",
"productStatAll": "المنتجات",
"productStatActive": "نشطة",
"productStatOutOfStock": "نافد",
"showList": "عرض قائمة",
"showGrid": "عرض شبكة",
"newProduct": "منتج جديد",
"editProduct": "تعديل المنتج",
"addProductPhoto": "إضافة صورة المنتج",
"tapToChangePhoto": "اضغط لتغيير صورة المنتج",
"fieldProductName": "اسم المنتج",
"fieldCategory": "الفئة",
"fieldUnit": "الوحدة",
"fieldDescription": "الوصف",
"fieldPrice": "السعر",
"fieldCostPrice": "سعر التكلفة",
"fieldSku": "الرمز التعريفي",
"fieldBarcode": "الباركود",
"fieldMinStockLevel": "الحد الأدنى للمخزون",
"fieldExpiryAlertDays": "تنبيه انتهاء الصلاحية (أيام)",
"saveChanges": "حفظ التغييرات",
"stockByShop": "المخزون حسب المتجر",
"productPhotoSubtitle": "اضغط لتغيير صورة المنتج"
```

### Keys added in Task 5 (Categories)

**English:**
```json
"newCategory": "New Category",
"editCategory": "Edit Category",
"noCategoriesYet": "No categories yet",
"fieldCategoryName": "Category Name",
"createCategory": "Create Category",
"catStatTotal": "Total",
"catStatActive": "Active",
"catStatInactive": "Inactive",
"catStatSub": "Sub",
"catAppBarProducts": "Products",
"catAppBarSub": "Sub",
"catAppBarStatus": "Status"
```

**Arabic:**
```json
"newCategory": "فئة جديدة",
"editCategory": "تعديل الفئة",
"noCategoriesYet": "لا توجد فئات بعد",
"fieldCategoryName": "اسم الفئة",
"createCategory": "إنشاء فئة",
"catStatTotal": "الإجمالي",
"catStatActive": "نشطة",
"catStatInactive": "غير نشطة",
"catStatSub": "فرعية",
"catAppBarProducts": "المنتجات",
"catAppBarSub": "الفرعية",
"catAppBarStatus": "الحالة"
```

### Keys added in Task 6 (Users/Cashiers)

**English:**
```json
"addCashier": "Add Cashier",
"userStatTotal": "Total",
"userStatActive": "Active",
"userStatCashiers": "Cashiers",
"userStatManagers": "Managers",
"newUser": "New User",
"editUser": "Edit User",
"createStaffAccount": "Create staff account",
"editStaffAccount": "Edit staff account",
"fieldPhone": "Phone",
"fieldRole": "Role",
"fieldAssignedShop": "Assigned Shop",
"createUser": "Create User",
"userInfoTitle": "Account Info",
"userInfoSubtitle": "Basic cashier profile and access status.",
"userActivityTitle": "Activity",
"userActivitySubtitle": "Login and account creation details.",
"userDetailPhone": "Phone",
"userDetailRole": "Role",
"userDetailVerified": "Verified",
"userDetailStatus": "Status",
"userDetailLastLogin": "Last login",
"userDetailJoined": "Joined",
"deactivateUser": "Deactivate User?",
"managerAccess": "Manager access",
"shopRequired": "Shop required",
"shopAssigned": "Shop assigned",
"unassignedCashier": "Unassigned cashier"
```

**Arabic:**
```json
"addCashier": "إضافة كاشير",
"userStatTotal": "الإجمالي",
"userStatActive": "نشطة",
"userStatCashiers": "الكاشيرات",
"userStatManagers": "المديرون",
"newUser": "مستخدم جديد",
"editUser": "تعديل المستخدم",
"createStaffAccount": "إنشاء حساب موظف",
"editStaffAccount": "تعديل حساب الموظف",
"fieldPhone": "الهاتف",
"fieldRole": "الدور",
"fieldAssignedShop": "المتجر المُعيَّن",
"createUser": "إنشاء مستخدم",
"userInfoTitle": "معلومات الحساب",
"userInfoSubtitle": "الملف الأساسي للكاشير وحالة الوصول.",
"userActivityTitle": "النشاط",
"userActivitySubtitle": "تفاصيل تسجيل الدخول وإنشاء الحساب.",
"userDetailPhone": "الهاتف",
"userDetailRole": "الدور",
"userDetailVerified": "تم التحقق",
"userDetailStatus": "الحالة",
"userDetailLastLogin": "آخر تسجيل دخول",
"userDetailJoined": "تاريخ الانضمام",
"deactivateUser": "إلغاء تفعيل المستخدم؟",
"managerAccess": "صلاحيات المدير",
"shopRequired": "المتجر مطلوب",
"shopAssigned": "تم تعيين المتجر",
"unassignedCashier": "كاشير غير معيَّن"
```

### Keys added in Task 7 (Customers)

**English:**
```json
"addCustomer": "Add Customer",
"customerStatTotal": "Total",
"customerStatActive": "Active",
"customerStatInactive": "Inactive",
"customerStatCredit": "Credit",
"customerStatPhone": "Phone",
"fieldCustomerName": "Customer Name",
"fieldAddress": "Address",
"fieldNotes": "Notes",
"fieldLoyaltyPoints": "Loyalty Points",
"createCustomer": "Create Customer",
"customerInactiveLabel": "Inactive",
"customerSearchHint": "Search customers, phone, email...",
"customerSalesPrefix": "Sales"
```

**Arabic:**
```json
"addCustomer": "إضافة عميل",
"customerStatTotal": "الإجمالي",
"customerStatActive": "نشط",
"customerStatInactive": "غير نشط",
"customerStatCredit": "الائتمان",
"customerStatPhone": "الهاتف",
"fieldCustomerName": "اسم العميل",
"fieldAddress": "العنوان",
"fieldNotes": "الملاحظات",
"fieldLoyaltyPoints": "نقاط الولاء",
"createCustomer": "إنشاء عميل",
"customerInactiveLabel": "غير نشط",
"customerSearchHint": "بحث في العملاء، الهاتف، البريد الإلكتروني...",
"customerSalesPrefix": "المبيعات"
```

### Keys added in Task 8 (Returns + Sales History)

**English:**
```json
"returnFindSale": "Find a sale to return",
"returnFindSaleSubtitle": "Enter a receipt number or amount above",
"returnSearchFailed": "Search failed",
"returnNoSalesFound": "No sales found",
"returnNoSalesSubtitle": "Try a different receipt number or amount",
"returnAll": "Return all",
"deselectAll": "Deselect all",
"refCopied": "Reference copied",
"shareReturnWhatsApp": "Share return receipt via WhatsApp",
"salesHistoryTitle": "Sales history",
"allSalesLoaded": "All sales loaded",
"saleReceiptFailure": "Failed to generate receipt PDF",
"returnItemsAction": "Return items from this sale",
"salesCouldNotLoad": "Could not load sales",
"saleComplete": "Sale complete!",
"savedOffline": "Saved offline",
"tapToCopy": "Tap to copy",
"totalPaid": "Total paid",
"shareViaWhatsApp": "Share via WhatsApp",
"shareVia": "Share via...",
"newSale": "New sale",
"receiptCopied": "Receipt number copied",
"saleSearchHint": "Search receipt, amount, payment...",
"amanaPosLabel": "AMANAPOS"
```

**Arabic:**
```json
"returnFindSale": "ابحث عن بيعة للإرجاع",
"returnFindSaleSubtitle": "أدخل رقم الإيصال أو المبلغ أعلاه",
"returnSearchFailed": "فشل البحث",
"returnNoSalesFound": "لم يتم العثور على مبيعات",
"returnNoSalesSubtitle": "جرّب رقم إيصال أو مبلغاً مختلفاً",
"returnAll": "إرجاع الكل",
"deselectAll": "إلغاء تحديد الكل",
"refCopied": "تم نسخ المرجع",
"shareReturnWhatsApp": "مشاركة إيصال الإرجاع عبر واتساب",
"salesHistoryTitle": "سجل المبيعات",
"allSalesLoaded": "تم تحميل جميع المبيعات",
"saleReceiptFailure": "فشل إنشاء ملف الإيصال",
"returnItemsAction": "إرجاع عناصر من هذه البيعة",
"salesCouldNotLoad": "تعذّر تحميل المبيعات",
"saleComplete": "تمت البيعة!",
"savedOffline": "محفوظ بلا إنترنت",
"tapToCopy": "اضغط للنسخ",
"totalPaid": "إجمالي المدفوع",
"shareViaWhatsApp": "مشاركة عبر واتساب",
"shareVia": "مشاركة عبر...",
"newSale": "بيعة جديدة",
"receiptCopied": "تم نسخ رقم الإيصال",
"saleSearchHint": "بحث في الإيصالات، المبالغ، المدفوعات...",
"amanaPosLabel": "أمانة"
```

### Keys added in Task 9 (Notifications + Main Screen)

**English:**
```json
"notificationsTitle": "Notifications",
"somethingWentWrong": "Something went wrong",
"posStatusOffline": "OFFLINE",
"posStatusSyncIssue": "SYNC ISSUE",
"posStatusPending": "PENDING",
"posStatusSyncing": "SYNCING",
"posStatusSynced": "SYNCED",
"clearLocalDataTitle": "Clear local data?",
"localDataCleared": "Local data cleared.",
"salesChipLabel": "SALES",
"avgChipLabel": "AVG",
"viewPendingCount": "View {count} pending",
"@viewPendingCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

**Arabic:**
```json
"notificationsTitle": "الإشعارات",
"somethingWentWrong": "حدث خطأ ما",
"posStatusOffline": "غير متصل",
"posStatusSyncIssue": "مشكلة مزامنة",
"posStatusPending": "في الانتظار",
"posStatusSyncing": "جارٍ المزامنة",
"posStatusSynced": "تمت المزامنة",
"clearLocalDataTitle": "مسح البيانات المحلية؟",
"localDataCleared": "تم مسح البيانات المحلية.",
"salesChipLabel": "المبيعات",
"avgChipLabel": "المتوسط",
"viewPendingCount": "عرض {count} معلّق",
"@viewPendingCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

### Keys added in Task 10 (Inventory)

**English:**
```json
"invExpiryExpired": "Expired",
"invExpiryExpiringSoon": "Expiring Soon",
"invHeroExport": "Export",
"invHeroScan": "Scan",
"invInventoryHealth": "Inventory Health",
"invNeedsRestock": "Needs Restock",
"invInboundThisMonth": "Inbound This Month",
"invExpiringDays": "Expiring ≤30 days",
"invQuickActionsTitle": "Quick Actions",
"invReceive": "Receive",
"invStockAction": "Stock",
"invVendors": "Vendors",
"invExpiry": "Expiry",
"invHealthRingTitle": "Health Ring",
"invHealthy": "Healthy",
"invLow": "Low",
"invOut": "Out",
"invInboundVelocityTitle": "Inbound Velocity",
"invExpiryTimelineTitle": "Expiry Timeline",
"invRecentReceiptsTitle": "Recent Receipts",
"invVendorBoardTitle": "Vendor Board",
"invRestockQueueTitle": "Restock Queue",
"invVendorSaved": "Vendor saved",
"invVendorFailed": "Failed to save vendor",
"invAddFirstVendor": "Add your first vendor",
"invSelectVendor": "Select vendor",
"invAddRow": "Add Row",
"invMovementType": "Movement Type",
"invFieldQuantity": "Quantity",
"invFieldReference": "Reference",
"invConfirmMovement": "Confirm Movement",
"invFieldNewQuantity": "New Quantity",
"invFieldNotes": "Notes",
"invAdjustStock": "Adjust Stock",
"invTransferTo": "Transfer To",
"invQtyToTransfer": "Quantity to Transfer",
"invTransferStock": "Transfer Stock",
"invAddIn": "Add In",
"invAdjust": "Adjust",
"invTransfer": "Transfer"
```

**Arabic:**
```json
"invExpiryExpired": "منتهية الصلاحية",
"invExpiryExpiringSoon": "تنتهي قريباً",
"invHeroExport": "تصدير",
"invHeroScan": "مسح ضوئي",
"invInventoryHealth": "صحة المخزون",
"invNeedsRestock": "يحتاج تزويد",
"invInboundThisMonth": "الواردات هذا الشهر",
"invExpiringDays": "ينتهي ≤٣٠ يوماً",
"invQuickActionsTitle": "الإجراءات السريعة",
"invReceive": "استلام",
"invStockAction": "مخزون",
"invVendors": "الموردون",
"invExpiry": "الصلاحية",
"invHealthRingTitle": "حلقة الصحة",
"invHealthy": "جيد",
"invLow": "منخفض",
"invOut": "نافد",
"invInboundVelocityTitle": "وتيرة الاستلام",
"invExpiryTimelineTitle": "جدول انتهاء الصلاحية",
"invRecentReceiptsTitle": "الإيصالات الأخيرة",
"invVendorBoardTitle": "لوحة الموردين",
"invRestockQueueTitle": "قائمة التزويد",
"invVendorSaved": "تم حفظ المورد",
"invVendorFailed": "فشل حفظ المورد",
"invAddFirstVendor": "أضف موردك الأول",
"invSelectVendor": "اختر موردًا",
"invAddRow": "إضافة صف",
"invMovementType": "نوع الحركة",
"invFieldQuantity": "الكمية",
"invFieldReference": "المرجع",
"invConfirmMovement": "تأكيد الحركة",
"invFieldNewQuantity": "الكمية الجديدة",
"invFieldNotes": "الملاحظات",
"invAdjustStock": "تعديل المخزون",
"invTransferTo": "نقل إلى",
"invQtyToTransfer": "الكمية المراد نقلها",
"invTransferStock": "نقل المخزون",
"invAddIn": "إضافة وارد",
"invAdjust": "تعديل",
"invTransfer": "نقل"
```

### Keys added in Task 11 (Business)

**English:**
```json
"bizManageLabel": "MANAGE",
"bizShopsTitle": "Shops",
"bizActiveBranch": "Active branch",
"bizActiveBranches": "Active branches",
"bizProductsItem": "Products item",
"bizProductsItems": "Products items",
"bizUserSingular": "User",
"bizUserPlural": "Users",
"bizReportSubtitle": "Browse and search all transactions",
"bizCreateMyBusiness": "Create My Business",
"bizAddFirstShop": "Add First Shop",
"bizFieldBusinessName": "Business Name",
"bizFieldAddress": "Address",
"bizFieldPhone": "Phone",
"bizFieldEmail": "Email",
"bizInfoTitle": "Business Information",
"bizInfoSubtitle": "Basic profile and contact details",
"bizDeactivateTitle": "Deactivate Business?",
"bizFieldShopName": "Shop Name",
"shopStatTotalShops": "Total Shops",
"shopStatActive": "Active",
"shopStatInactive": "Inactive",
"bizStatusLabel": "Status",
"bizAddressLabel": "Address",
"bizPhoneLabel": "Phone",
"bizEmailLabel": "Email",
"bizShopsLabel": "Shops"
```

**Arabic:**
```json
"bizManageLabel": "الإدارة",
"bizShopsTitle": "المتاجر",
"bizActiveBranch": "فرع نشط",
"bizActiveBranches": "فروع نشطة",
"bizProductsItem": "منتج",
"bizProductsItems": "منتجات",
"bizUserSingular": "مستخدم",
"bizUserPlural": "مستخدمون",
"bizReportSubtitle": "استعراض وبحث في جميع المعاملات",
"bizCreateMyBusiness": "إنشاء نشاطي التجاري",
"bizAddFirstShop": "إضافة أول متجر",
"bizFieldBusinessName": "اسم النشاط التجاري",
"bizFieldAddress": "العنوان",
"bizFieldPhone": "الهاتف",
"bizFieldEmail": "البريد الإلكتروني",
"bizInfoTitle": "معلومات النشاط التجاري",
"bizInfoSubtitle": "الملف الأساسي وتفاصيل الاتصال",
"bizDeactivateTitle": "إلغاء تفعيل النشاط التجاري؟",
"bizFieldShopName": "اسم المتجر",
"shopStatTotalShops": "إجمالي المتاجر",
"shopStatActive": "نشطة",
"shopStatInactive": "غير نشطة",
"bizStatusLabel": "الحالة",
"bizAddressLabel": "العنوان",
"bizPhoneLabel": "الهاتف",
"bizEmailLabel": "البريد الإلكتروني",
"bizShopsLabel": "المتاجر"
```

---

### Task 1: Create DirectionalIcon helper widget

**Files:**
- Create: `lib/widgets/directional_icon.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

/// Wraps any icon and optionally mirrors it horizontally in RTL layouts.
///
/// Use for directional icons (←/→ navigation, chevrons) that should flip
/// in Arabic. Do NOT use for vertical icons (↑/↓ dropdowns) — keep those
/// as plain [Icon] widgets.
///
/// Usage:
///   DirectionalIcon(icon: SolarIconsOutline.altArrowLeft, flipInRtl: true, size: 18, color: colors.textPrimary)
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final bool flipInRtl;
  final double? size;
  final Color? color;

  const DirectionalIcon({
    super.key,
    required this.icon,
    this.flipInRtl = true,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, size: size, color: color);
    if (flipInRtl && Directionality.of(context) == TextDirection.rtl) {
      return Transform.scale(scaleX: -1, child: child);
    }
    return child;
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/widgets/directional_icon.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/directional_icon.dart
git commit -m "feat(l10n): add DirectionalIcon widget for RTL arrow flipping"
```

---

### Task 2: ARB batch 1 — Login + Settings sheets

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Modify: `lib/features/login/presentation/widgets/login_form.dart`
- Modify: `lib/features/login/presentation/widgets/login_otp.dart`
- Modify: `lib/features/settings/presentation/widgets/theme_picker_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/edit_profile_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/set_password_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/edit_bankak_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/bankak_payment_card.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Append Task 2 keys to `lib/l10n/app_en.arb`**

Open `lib/l10n/app_en.arb`. Before the closing `}`, add a comma after the last existing entry (`"themeSystem": "System"`) and insert all the Task 2 English keys from the ARB Key Reference section above (loginWelcomeTitle through bankakAddButton).

The file should end with:
```json
  "themeLight": "Light",
  "themeDark": "Dark",
  "themeSystem": "System",

  "loginWelcomeTitle": "Welcome back",
  "loginSubtitle": "Enter your mobile number to receive a 6-digit verification code.",
  "loginMobileLabel": "Mobile number",
  "loginContinue": "Continue",
  "loginTermsPrefix": "By continuing you agree to our ",
  "loginTermsLink": "Terms",
  "loginTermsSeparator": " & ",
  "loginPrivacyLink": "Privacy Policy",

  "otpTitle": "Verification code",
  "otpSentPrefix": "We sent a 6-digit code to\n",
  "otpChange": "Change",
  "otpResendIn": "Resend code in ",
  "otpResendButton": "Resend code",
  "otpVerifyButton": "Verify & continue",
  "otpVerifiedButton": "Verified",
  "otpVerifiedSigningIn": "Verified — signing you in…",

  "themePickerTitle": "Appearance",
  "themePickerSubtitle": "Choose how AmanaPOS looks on your device.",
  "themeLightSubtitle": "Clean bright interface. Always on.",
  "themeDarkSubtitle": "Easy on the eyes in low light.",
  "themeSystemSubtitle": "Follows your device setting automatically.",

  "editProfileTitle": "Edit Profile",
  "editProfileSubtitle": "Update your name and contact information.",
  "fieldFullName": "Full Name",
  "fieldEmail": "Email",
  "saveProfile": "Save Profile",

  "setPasswordTitle": "Set Password",
  "setPasswordSubtitle": "Use a strong password to protect your AmanaPOS account.",
  "fieldNewPassword": "New Password",
  "fieldConfirmPassword": "Confirm Password",
  "updatePassword": "Update Password",

  "bankakAddTitle": "Add Bankak Account",
  "bankakChangeTitle": "Change Bankak Account",
  "bankakSheetSubtitle": "Used when cashier selects Bankak as payment method in POS.",
  "bankakInfoNote": "AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.",
  "bankakAccountNumber": "Bankak Account Number",
  "bankakSaveChanges": "Save Changes",
  "bankakAddAccount": "Add Account",
  "bankakRemove": "Remove",
  "bankakActive": "Active",
  "bankakNotSet": "Not set",
  "bankakUsedForLabel": "Used for Bankak sales tracking and reports.",
  "bankakPosNote": "When cashier chooses Bankak in POS, AmanaPOS records the sale under this account.",
  "bankakCardTitle": "Bankak Payments",
  "bankakChangeButton": "Change Bankak Account",
  "bankakAddButton": "Add Bankak Account"
}
```

- [ ] **Step 2: Append Task 2 keys to `lib/l10n/app_ar.arb`**

Same pattern — add Arabic equivalents from the ARB Key Reference. Match the same key names exactly.

- [ ] **Step 3: Run code generation**

```bash
cd /Users/almogdadjabir/StudioProjects/amana_pos && flutter gen-l10n
```

Expected: No errors. Regenerated files in `lib/l10n/`.

- [ ] **Step 4: Migrate `lib/features/login/presentation/widgets/login_form.dart`**

Add import at top:
```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
```

In the `build` method, add `final tr = context.tr;` at the top of the `builder:` callback.

Replace:
```dart
Text('Welcome back', ...),
```
With:
```dart
Text(tr.loginWelcomeTitle, ...),
```

Replace:
```dart
Text('Enter your mobile number to receive a 6-digit verification code.', ...),
```
With:
```dart
Text(tr.loginSubtitle, ...),
```

Replace:
```dart
Text('Mobile number', ...),
```
With:
```dart
Text(tr.loginMobileLabel, ...),
```

Replace:
```dart
AppButton.wide(
  label: 'Continue',
  ...
```
With:
```dart
AppButton.wide(
  label: tr.loginContinue,
  ...
```

Replace the `Text.rich` terms block:
```dart
// BEFORE:
const TextSpan(text: 'By continuing you agree to our '),
TextSpan(text: 'Terms', ...),
const TextSpan(text: ' & '),
TextSpan(text: 'Privacy Policy', ...),
const TextSpan(text: '.'),

// AFTER (remove const because tr is not const):
TextSpan(text: tr.loginTermsPrefix),
TextSpan(text: tr.loginTermsLink, ...),
TextSpan(text: tr.loginTermsSeparator),
TextSpan(text: tr.loginPrivacyLink, ...),
const TextSpan(text: '.'),
```

- [ ] **Step 5: Migrate `lib/features/login/presentation/widgets/login_otp.dart`**

Add import:
```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
```

Add `final tr = context.tr;` at top of `builder:` callback.

Replace:
```dart
Text('Verification code', ...),
```
With:
```dart
Text(tr.otpTitle, ...),
```

Replace `Text.rich` sent-to block:
```dart
// BEFORE:
const TextSpan(text: 'We sent a 6-digit code to\n'),
// ... phone span ...
WidgetSpan(child: GestureDetector(
  child: Text('Change', ...),
))

// AFTER:
TextSpan(text: tr.otpSentPrefix),
// ... phone span unchanged ...
WidgetSpan(child: GestureDetector(
  child: Text(tr.otpChange, ...),
))
```

Replace resend timer text:
```dart
// BEFORE:
const TextSpan(text: 'Resend code in '),
// AFTER:
TextSpan(text: tr.otpResendIn),
```

Replace resend button label:
```dart
// BEFORE:
label: Text('Resend code', ...),
// AFTER:
label: Text(tr.otpResendButton, ...),
```

Replace verify button and verified status banner:
```dart
// BEFORE:
AppButton.wide(label: state.isPinMatched ? 'Verified' : 'Verify & continue', ...)
// AFTER:
AppButton.wide(label: state.isPinMatched ? tr.otpVerifiedButton : tr.otpVerifyButton, ...)
```

Replace `_StatusBanner` verified message (the non-error branch):
```dart
// BEFORE (in OTPInputSquare error/success section):
_StatusBanner(message: 'Verified — signing you in…', isError: false)

// AFTER:
_StatusBanner(message: tr.otpVerifiedSigningIn, isError: false)
```

Note: `_StatusBanner` receives `message` as a parameter, so it doesn't need changes itself. The caller passes the localized string.

- [ ] **Step 6: Migrate `lib/features/settings/presentation/widgets/theme_picker_sheet.dart`**

Add import:
```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
```

In `build`, add `final tr = context.tr;`.

Replace `AppBottomSheet` title and subtitle:
```dart
// BEFORE:
AppBottomSheet(
  title: 'Appearance',
  subtitle: 'Choose how AmanaPOS looks on your device.',
  ...
// AFTER:
AppBottomSheet(
  title: tr.themePickerTitle,
  subtitle: tr.themePickerSubtitle,
  ...
```

Replace each theme option's `title` and `subtitle`:
```dart
// BEFORE:
title: 'Light', subtitle: 'Clean bright interface. Always on.'
title: 'Dark', subtitle: 'Easy on the eyes in low light.'
title: 'System', subtitle: 'Follows your device setting automatically.'

// AFTER:
title: tr.themeLight, subtitle: tr.themeLightSubtitle
title: tr.themeDark, subtitle: tr.themeDarkSubtitle
title: tr.themeSystem, subtitle: tr.themeSystemSubtitle
```

Remove `const` from `ThemePickerSheet` constructor if needed (non-const tr usage).

- [ ] **Step 7: Migrate `lib/features/settings/presentation/settings_screen.dart` (theme labels)**

These are the three inline theme option rows inside the settings screen's Appearance section at lines ~500, 507, 514.

Add `final tr = context.tr;` if not already present in that build context.

Replace:
```dart
label: 'Light',
label: 'System',
label: 'Dark',
```
With:
```dart
label: tr.themeLight,
label: tr.themeSystem,
label: tr.themeDark,
```

- [ ] **Step 8: Migrate `lib/features/settings/presentation/widgets/edit_profile_sheet.dart`**

Add import and `final tr = context.tr;`.

Replace:
```dart
title: 'Edit Profile',
subtitle: 'Update your name and contact information.',
FieldLabel(label: 'Full Name', required: true),
// hint: 'Owner full name' — leave as-is (placeholder example)
FieldLabel(label: 'Email'),
// hint: 'email@example.com' — leave as-is
AppButton(label: 'Save Profile', ...)
```
With:
```dart
title: tr.editProfileTitle,
subtitle: tr.editProfileSubtitle,
FieldLabel(label: tr.fieldFullName, required: true),
FieldLabel(label: tr.fieldEmail),
AppButton(label: tr.saveProfile, ...)
```

- [ ] **Step 9: Migrate `lib/features/settings/presentation/widgets/set_password_sheet.dart`**

Add import and `final tr = context.tr;`.

Replace:
```dart
title: 'Set Password',
subtitle: 'Use a strong password to protect your AmanaPOS account.',
FieldLabel(label: 'New Password', required: true),
FieldLabel(label: 'Confirm Password', required: true),
// hint: 'New password' — leave as-is
// hint: 'Confirm password' — leave as-is
label: 'Update Password',
```
With:
```dart
title: tr.setPasswordTitle,
subtitle: tr.setPasswordSubtitle,
FieldLabel(label: tr.fieldNewPassword, required: true),
FieldLabel(label: tr.fieldConfirmPassword, required: true),
label: tr.updatePassword,
```

- [ ] **Step 10: Migrate `lib/features/settings/presentation/widgets/edit_bankak_sheet.dart`**

Add import and `final tr = context.tr;`.

Replace:
```dart
// BEFORE:
title: hasExisting ? 'Change Bankak Account' : 'Add Bankak Account',
subtitle: 'Used when cashier selects Bankak as payment method in POS.',
// info text:
'AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.',
FieldLabel(label: 'Bankak Account Number', required: true),
// hint: 'Example: 1234567890' — leave as-is
label: const Text('Remove'),
label: hasExisting ? 'Save Changes' : 'Add Account',

// AFTER:
title: hasExisting ? tr.bankakChangeTitle : tr.bankakAddTitle,
subtitle: tr.bankakSheetSubtitle,
// info text:
tr.bankakInfoNote,
FieldLabel(label: tr.bankakAccountNumber, required: true),
label: Text(tr.bankakRemove),
label: hasExisting ? tr.bankakSaveChanges : tr.bankakAddAccount,
```

- [ ] **Step 11: Migrate `lib/features/settings/presentation/widgets/bankak_payment_card.dart`**

Add import and use `context.tr` in build methods. Because this widget has multiple `build` methods and nested widgets, use `final tr = context.tr;` at the top of each relevant `build`.

Replace:
```dart
'Bankak Payments'        → tr.bankakCardTitle
'Change Bankak Account'  → tr.bankakChangeButton (in label: const Text)
'Add Bankak Account'     → tr.bankakAddButton (in label: const Text)
configured ? 'Active' : 'Not set'  → configured ? tr.bankakActive : tr.bankakNotSet
'Used for Bankak sales tracking and reports.'  → tr.bankakUsedForLabel
'When cashier chooses Bankak in POS...'        → tr.bankakPosNote
'Bankak Account Number'  → tr.bankakAccountNumber (in FieldLabel)
label: const Text('Remove')  → label: Text(tr.bankakRemove)
hasExisting ? 'Save Changes' : 'Add Account'  → hasExisting ? tr.bankakSaveChanges : tr.bankakAddAccount
```

Remove `const` from button labels where they now use `tr`.

- [ ] **Step 12: Analyze batch**

```bash
flutter analyze lib/features/login/ lib/features/settings/presentation/widgets/ lib/features/settings/presentation/settings_screen.dart
```

Expected: No new errors.

- [ ] **Step 13: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/app_localizations*.dart \
  lib/features/login/presentation/widgets/ \
  lib/features/settings/presentation/widgets/theme_picker_sheet.dart \
  lib/features/settings/presentation/widgets/edit_profile_sheet.dart \
  lib/features/settings/presentation/widgets/set_password_sheet.dart \
  lib/features/settings/presentation/widgets/edit_bankak_sheet.dart \
  lib/features/settings/presentation/widgets/bankak_payment_card.dart \
  lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(l10n): migrate login + settings sheets strings and Arabic ARB keys"
```

---

### Task 3: ARB batch 2 — POS screen

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/pos/presentation/pos_screen.dart`
- Modify: `lib/features/pos/presentation/widgets/category_bar.dart`
- Modify: `lib/features/pos/presentation/widgets/pos_search_section.dart`

- [ ] **Step 1: Append Task 3 keys to both ARB files**

Add the 10 POS keys (posTodaySales through posShopMismatch) from the ARB Key Reference to both `app_en.arb` and `app_ar.arb`.

- [ ] **Step 2: Run gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 3: Migrate `lib/features/pos/presentation/pos_screen.dart`**

Add import:
```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
```

POS screen has several BlocListener/BlocBuilder blocks. Add `final tr = context.tr;` at the top of the Scaffold's `builder:` context where it's accessible, and use it for the string occurrences below.

Replace the Bankak error message:
```dart
// BEFORE:
message: 'Bankak account is not set up. Go to Settings and add your account number first.',

// AFTER:
message: context.tr.posBankakNotSetup,
```

Replace the cashier-not-assigned message:
```dart
// BEFORE:
final message = permissions.isCashier
    ? 'You are not assigned to a shop. Contact your manager.'
    : 'No shop found. Please refresh and try again.';

// AFTER:
final message = permissions.isCashier
    ? context.tr.posCashierNotAssigned
    : context.tr.posNoShopFound;
```

Replace the sale success message:
```dart
// BEFORE:
final message = state.submitError?.isNotEmpty == true
    ? state.submitError!
    : 'Sale completed successfully';

// AFTER:
final message = state.submitError?.isNotEmpty == true
    ? state.submitError!
    : context.tr.posSaleCompleted;
```

Replace the failure message with its error code branches:
```dart
// BEFORE:
final message = raw.contains('BANKAK_ACCOUNT_REQUIRED')
    ? 'Please add your Bankak account number in Settings.'
    : raw.contains('SHOP_MISMATCH')
    ? 'You are not assigned to this shop. Contact your manager.'
    : raw;

// AFTER:
final message = raw.contains('BANKAK_ACCOUNT_REQUIRED')
    ? context.tr.posBankakRequired
    : raw.contains('SHOP_MISMATCH')
    ? context.tr.posShopMismatch
    : raw;
```

Replace `'Today sales'` label (the `labelName` fallback):
```dart
// BEFORE:
final labelName = isCashier ? cashierName : 'Today sales';

// AFTER:
final labelName = isCashier ? cashierName : context.tr.posTodaySales;
```

- [ ] **Step 4: Migrate `lib/features/pos/presentation/widgets/category_bar.dart`**

Add import and `final tr = context.tr;` (this widget already has a `build` with context).

Replace:
```dart
label: 'All',
```
With:
```dart
label: tr.posAllCategory,
```

Remove `const` from the "All" NavTab if needed.

- [ ] **Step 5: Migrate `lib/features/pos/presentation/widgets/pos_search_section.dart`**

Add import and replace:
```dart
// BEFORE:
hintText: 'Search · SKU · Barcode',

// AFTER:
hintText: context.tr.posSearchHint,
```

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze lib/features/pos/presentation/
git add lib/l10n/ lib/features/pos/presentation/pos_screen.dart \
  lib/features/pos/presentation/widgets/category_bar.dart \
  lib/features/pos/presentation/widgets/pos_search_section.dart
git commit -m "feat(l10n): migrate POS screen and search strings"
```

---

### Task 4: ARB batch 3 — Products feature

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/products/presentation/product_screen.dart`
- Modify: `lib/features/products/presentation/widgets/products_header_view.dart`
- Modify: `lib/features/products/presentation/widgets/add_product_sheet.dart`
- Modify: `lib/features/products/presentation/widgets/edit_product_sheet.dart`
- Modify: `lib/features/products/presentation/widgets/delete_product_sheet.dart`
- Modify: `lib/features/products/presentation/widgets/product_sheet_shell.dart`
- Modify: `lib/features/products/presentation/product_detail_screen.dart`
- Modify: `lib/features/products/presentation/widgets/product_barcode_field.dart`
- Modify: `lib/features/products/presentation/widgets/product_inventory_alerts_section.dart`
- Modify: `lib/features/products/presentation/widgets/product_details/product_actions_view.dart`

- [ ] **Step 1: Append Task 4 keys to both ARB files**

Add all Product keys from the ARB Key Reference (productsManagement through productPhotoSubtitle).

- [ ] **Step 2: Run gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 3: Migrate `lib/features/products/presentation/product_screen.dart`**

Add import and `final tr = context.tr;` in the Scaffold's `buildWhen` builder.

Replace:
```dart
title: Text('Products Management', ...)  → title: Text(tr.productsManagement, ...)
tooltip: state.isGrid ? 'Show list' : 'Show grid'  → tooltip: state.isGrid ? tr.showList : tr.showGrid
label: Text('Add Product', ...)  → label: Text(tr.addProduct, ...)
title: 'No products yet'  → title: tr.noProductsYet
message: 'Add your first product to start building your catalog and begin selling.'  → message: tr.noProductsMessage
primaryActionText: 'Add Product'  → primaryActionText: tr.addProduct
```

- [ ] **Step 4: Migrate `lib/features/products/presentation/widgets/products_header_view.dart`**

Replace:
```dart
label: 'Products'  → label: tr.productStatAll
label: 'Active'    → label: tr.productStatActive
label: 'Out'       → label: tr.productStatOutOfStock
```

- [ ] **Step 5: Migrate `lib/features/products/presentation/widgets/add_product_sheet.dart`**

Add import. Find all occurrences and replace:
```dart
title: 'New Product'              → title: tr.newProduct
title: 'Add product photo'        → title: tr.addProductPhoto
subtitle: 'Tap to change...'      → subtitle: tr.productPhotoSubtitle
FieldLabel(label: 'Product Name', ...) → FieldLabel(label: tr.fieldProductName, ...)
FieldLabel(label: 'Category', ...) → FieldLabel(label: tr.fieldCategory, ...)
FieldLabel(label: 'Unit', ...)    → FieldLabel(label: tr.fieldUnit, ...)
FieldLabel(label: 'Description')  → FieldLabel(label: tr.fieldDescription)
```

The `product_sheet_shell.dart` handles price/cost/sku/barcode fields — those are migrated in step 7.

The submit button label is handled by `ProductSubmitButton` which takes a `label` string from the caller. The caller in `add_product_sheet.dart` does NOT pass a label (uses default) — check the actual call. If it passes `'Add Product'` or similar, replace with `tr.addProduct`.

- [ ] **Step 6: Migrate `lib/features/products/presentation/widgets/edit_product_sheet.dart`**

Replace:
```dart
title: 'Edit Product'             → title: tr.editProduct
title: 'Product photo'            → title: tr.addProductPhoto
subtitle: 'Tap to change product image'  → subtitle: tr.tapToChangePhoto
FieldLabel(label: 'Product Name', ...) → FieldLabel(label: tr.fieldProductName, ...)
FieldLabel(label: 'Category', ...) → FieldLabel(label: tr.fieldCategory, ...)
FieldLabel(label: 'Unit', ...)    → FieldLabel(label: tr.fieldUnit, ...)
FieldLabel(label: 'Description')  → FieldLabel(label: tr.fieldDescription)
ProductSubmitButton(label: 'Save Changes', ...) → ProductSubmitButton(label: tr.saveChanges, ...)
```

- [ ] **Step 7: Migrate `lib/features/products/presentation/widgets/product_sheet_shell.dart`**

Replace:
```dart
FieldLabel(label: 'Price', required: true)  → FieldLabel(label: tr.fieldPrice, required: true)
FieldLabel(label: 'Cost Price')             → FieldLabel(label: tr.fieldCostPrice)
FieldLabel(label: 'SKU')                    → FieldLabel(label: tr.fieldSku)
FieldLabel(label: 'Barcode')                → FieldLabel(label: tr.fieldBarcode)
```

Hint text (`hint: 'SKU-001'`) is a placeholder example — leave as-is.

- [ ] **Step 8: Migrate `lib/features/products/presentation/widgets/delete_product_sheet.dart`**

Replace:
```dart
child: const Text('Cancel')  → child: Text(tr.cancel)
child: const Text('Delete')  → child: Text(tr.delete)
```

Remove `const` from those Text widgets.

- [ ] **Step 9: Migrate `lib/features/products/presentation/product_detail_screen.dart`**

Replace:
```dart
title: 'Stock by Shop'  → title: tr.stockByShop
```

(Wrapped in `WorkspaceSectionHeader(title: ...)`)

- [ ] **Step 10: Migrate `lib/features/products/presentation/widgets/product_barcode_field.dart`**

Replace:
```dart
FieldLabel(label: 'Barcode')  → FieldLabel(label: tr.fieldBarcode)
```

- [ ] **Step 11: Migrate `lib/features/products/presentation/widgets/product_inventory_alerts_section.dart`**

Replace:
```dart
FieldLabel(label: 'Minimum Stock Level')   → FieldLabel(label: tr.fieldMinStockLevel)
FieldLabel(label: 'Expiry Alert (days)')   → FieldLabel(label: tr.fieldExpiryAlertDays)
```

- [ ] **Step 12: Migrate `lib/features/products/presentation/widgets/product_details/product_actions_view.dart`**

Replace:
```dart
label: 'Edit'    → label: tr.edit   (already in ARB from initial pass)
label: 'Delete'  → label: tr.delete (already in ARB)
```

- [ ] **Step 13: Analyze and commit**

```bash
flutter analyze lib/features/products/presentation/
git add lib/l10n/ lib/features/products/presentation/
git commit -m "feat(l10n): migrate products feature strings"
```

---

### Task 5: ARB batch 4 — Categories feature

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/category/presentation/category_screen.dart`
- Modify: `lib/features/category/presentation/widgets/categories_header.dart`
- Modify: `lib/features/category/presentation/widgets/category_stats.dart`
- Modify: `lib/features/category/presentation/widgets/add_category_sheet.dart`
- Modify: `lib/features/category/presentation/widgets/edit_category_sheet.dart`
- Modify: `lib/features/category/presentation/widgets/category_app_bar.dart`

- [ ] **Step 1: Append Task 5 keys to both ARB files and run gen-l10n**

Add all 12 category keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/category/presentation/category_screen.dart`**

Add import. Replace:
```dart
title: 'No categories yet'  → title: tr.noCategoriesYet
```

- [ ] **Step 3: Migrate `lib/features/category/presentation/widgets/categories_header.dart`**

Add import. Replace all four stat chip labels:
```dart
label: 'Total'     → label: tr.catStatTotal
label: 'Active'    → label: tr.catStatActive
label: 'Inactive'  → label: tr.catStatInactive
label: 'Sub'       → label: tr.catStatSub
```

- [ ] **Step 4: Migrate `lib/features/category/presentation/widgets/category_stats.dart`**

Same four replacements as `categories_header.dart` (there are two separate stat widgets — both need the same change):
```dart
label: 'Total'     → label: tr.catStatTotal
label: 'Active'    → label: tr.catStatActive
label: 'Inactive'  → label: tr.catStatInactive
label: 'Sub'       → label: tr.catStatSub
```

- [ ] **Step 5: Migrate `lib/features/category/presentation/widgets/add_category_sheet.dart`**

Add import. Replace:
```dart
title: 'New Category'              → title: tr.newCategory
FieldLabel(label: 'Category Name') → FieldLabel(label: tr.fieldCategoryName)
FieldLabel(label: 'Description')   → FieldLabel(label: tr.fieldDescription)
label: 'Create Category'           → label: tr.createCategory
```

Hint text (`'Beverages'`, `'Drinks, juices...'`) — leave as-is.

- [ ] **Step 6: Migrate `lib/features/category/presentation/widgets/edit_category_sheet.dart`**

Add import. Replace:
```dart
title: 'Edit Category'             → title: tr.editCategory
FieldLabel(label: 'Name', ...)     → FieldLabel(label: tr.fieldCategoryName, ...)
FieldLabel(label: 'Description')   → FieldLabel(label: tr.fieldDescription)
label: 'Save Changes'              → label: tr.saveChanges
```

- [ ] **Step 7: Migrate `lib/features/category/presentation/widgets/category_app_bar.dart`**

Add import. Replace the three filter chip labels used in the sort/filter bar:
```dart
label: 'Products'  → label: tr.catAppBarProducts
label: 'Sub'       → label: tr.catAppBarSub
label: 'Status'    → label: tr.catAppBarStatus
```

- [ ] **Step 8: Analyze and commit**

```bash
flutter analyze lib/features/category/presentation/
git add lib/l10n/ lib/features/category/presentation/
git commit -m "feat(l10n): migrate categories feature strings"
```

---

### Task 6: ARB batch 5 — Users/Cashiers feature

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/users/presentation/users_screen.dart`
- Modify: `lib/features/users/presentation/user_detail_screen.dart`
- Modify: `lib/features/users/presentation/widgets/add_user_sheet.dart`
- Modify: `lib/features/users/presentation/widgets/edit_user_sheet.dart`
- Modify: `lib/features/users/presentation/widgets/deactivate_user_sheet.dart`

- [ ] **Step 1: Append Task 6 keys to both ARB files and run gen-l10n**

Add all 25 user keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/users/presentation/users_screen.dart`**

Add import. Replace in AppBar section:
```dart
Text('Add Cashier', ...)  → Text(tr.addCashier, ...)
```

Replace in stats section:
```dart
label: 'Total'     → label: tr.userStatTotal
label: 'Active'    → label: tr.userStatActive
label: 'Cashiers'  → label: tr.userStatCashiers
label: 'Managers'  → label: tr.userStatManagers
```

- [ ] **Step 3: Migrate `lib/features/users/presentation/user_detail_screen.dart`**

Add import. Replace:
```dart
title: 'Account Info'                        → title: tr.userInfoTitle
subtitle: 'Basic cashier profile...'         → subtitle: tr.userInfoSubtitle
title: 'Activity'                            → title: tr.userActivityTitle
subtitle: 'Login and account creation...'    → subtitle: tr.userActivitySubtitle
label: 'Phone'     → label: tr.userDetailPhone
label: 'Role'      → label: tr.userDetailRole
label: 'Verified'  → label: tr.userDetailVerified
label: 'Status'    → label: tr.userDetailStatus
label: 'Last login' → label: tr.userDetailLastLogin
label: 'Joined'    → label: tr.userDetailJoined
```

- [ ] **Step 4: Migrate `lib/features/users/presentation/widgets/add_user_sheet.dart`**

Add import. Replace:
```dart
title: 'New User'                → title: tr.newUser
title: 'Create staff account'    → title: tr.createStaffAccount
FieldLabel(label: 'Full Name')   → FieldLabel(label: tr.fieldFullName)
FieldLabel(label: 'Phone')       → FieldLabel(label: tr.fieldPhone)
FieldLabel(label: 'Role')        → FieldLabel(label: tr.fieldRole)
label: 'Assigned Shop'           → label: tr.fieldAssignedShop
label: isLoading ? 'Creating...' : 'Create User'
  → label: isLoading ? '...' : tr.createUser
```

Note: `'Creating...'` is a loading state — translate as `tr.createUser` with the loading indicator, or skip translating the loading text (it's shown briefly). Use `tr.createUser` for both states since the loading spinner communicates state.

For the two dialog titles at lines 472 and 485:
```dart
title: 'Shop required'  → title: tr.shopRequired
title: 'Shop assigned'  → title: tr.shopAssigned
```

- [ ] **Step 5: Migrate `lib/features/users/presentation/widgets/edit_user_sheet.dart`**

Add import. Replace:
```dart
title: 'Edit User'               → title: tr.editUser
title: 'Edit staff account'      → title: tr.editStaffAccount
FieldLabel(label: 'Full Name')   → FieldLabel(label: tr.fieldFullName)
FieldLabel(label: 'Role')        → FieldLabel(label: tr.fieldRole)
FieldLabel(label: 'Assigned Shop') → FieldLabel(label: tr.fieldAssignedShop)
title: 'Manager access'          → title: tr.managerAccess
label: 'Save Changes'            → label: tr.saveChanges
title: 'Unassigned cashier'      → title: tr.unassignedCashier
title: 'Shop assigned'           → title: tr.shopAssigned
```

- [ ] **Step 6: Migrate `lib/features/users/presentation/widgets/deactivate_user_sheet.dart`**

Add import. Replace:
```dart
title: 'Deactivate User?'  → title: tr.deactivateUser
```

- [ ] **Step 7: Analyze and commit**

```bash
flutter analyze lib/features/users/presentation/
git add lib/l10n/ lib/features/users/presentation/
git commit -m "feat(l10n): migrate users/cashiers feature strings"
```

---

### Task 7: ARB batch 6 — Customers feature

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/customers/presentation/customers_screen.dart`
- Modify: `lib/features/customers/presentation/widgets/customer_form_sheet.dart`
- Modify: `lib/features/customers/presentation/widgets/delete_customer_sheet.dart`

- [ ] **Step 1: Append Task 7 keys to both ARB files and run gen-l10n**

Add all 14 customer keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/customers/presentation/customers_screen.dart`**

Add import. Add `final tr = context.tr;` in relevant build methods.

Replace stat chip labels (all four filter stats at top of screen):
```dart
label: 'Total'    → label: tr.customerStatTotal
label: 'Active'   → label: tr.customerStatActive
label: 'Inactive' → label: tr.customerStatInactive
label: 'Credit'   → label: tr.customerStatCredit
label: 'Phone'    → label: tr.customerStatPhone
```

Replace the inline 'Inactive' badge on customer tiles (line 713):
```dart
label: 'Inactive'  → label: tr.customerInactiveLabel
```

Replace the sales chip label (line 753 — dynamic value):
```dart
// BEFORE:
label: 'Sales ${customer.totalPurchases ?? '0.00'}',
// AFTER:
label: '${tr.customerSalesPrefix} ${customer.totalPurchases ?? '0.00'}',
```

Replace action buttons (lines 775, 779):
```dart
child: Text('Edit')    → child: Text(tr.edit)
child: Text('Delete')  → child: Text(tr.delete)
```

Replace FAB label (line 919):
```dart
label: const Text('Add Customer')  → label: Text(tr.addCustomer)
```

Replace Retry button (line 1000):
```dart
label: const Text('Retry')  → label: Text(tr.retry)
```

Replace search hint:
```dart
hintText: 'Search customers, phone, email...'  → hintText: tr.customerSearchHint
```

- [ ] **Step 3: Migrate `lib/features/customers/presentation/widgets/customer_form_sheet.dart`**

Add import. Replace:
```dart
FieldLabel(label: 'Customer Name', required: true) → FieldLabel(label: tr.fieldCustomerName, required: true)
FieldLabel(label: 'Phone', required: true)          → FieldLabel(label: tr.fieldPhone, required: true)
FieldLabel(label: 'Email')                          → FieldLabel(label: tr.fieldEmail)
FieldLabel(label: 'Address')                        → FieldLabel(label: tr.fieldAddress)
FieldLabel(label: 'Notes')                          → FieldLabel(label: tr.fieldNotes)
FieldLabel(label: 'Loyalty Points')                 → FieldLabel(label: tr.fieldLoyaltyPoints)
label: _isEdit ? 'Save Changes' : 'Create Customer'
  → label: _isEdit ? tr.saveChanges : tr.createCustomer
```

Hint text (`'Sara Ali'`, `'sara@example.com'`, etc.) — leave as-is.

- [ ] **Step 4: Migrate `lib/features/customers/presentation/widgets/delete_customer_sheet.dart`**

Replace:
```dart
child: const Text('Cancel')  → child: Text(tr.cancel)
child: const Text('Delete')  → child: Text(tr.delete)
```

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze lib/features/customers/presentation/
git add lib/l10n/ lib/features/customers/presentation/
git commit -m "feat(l10n): migrate customers feature strings"
```

---

### Task 8: ARB batch 7 — Returns + Sales History

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/returns/presentation/returns_screen.dart`
- Modify: `lib/features/returns/presentation/widgets/returns_search_view.dart`
- Modify: `lib/features/returns/presentation/widgets/return_success_sheet.dart`
- Modify: `lib/features/sales_history/presentation/sales_history_screen.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_app_bar.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_footer.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_error_view.dart`
- Modify: `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`

- [ ] **Step 1: Append Task 8 keys to both ARB files and run gen-l10n**

Add all 24 returns/sales-history keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/returns/presentation/returns_screen.dart`**

Add import. Replace:
```dart
// In the AppBar action button (line ~117):
state.allSelected ? 'Deselect all' : 'Return all'
→ state.allSelected ? tr.deselectAll : tr.returnAll
```

- [ ] **Step 3: Migrate `lib/features/returns/presentation/widgets/returns_search_view.dart`**

Add import. Replace the three state view title/subtitle pairs:
```dart
// Empty state (no search yet):
title: 'Find a sale to return'
subtitle: 'Enter a receipt number or amount above'
→ title: tr.returnFindSale, subtitle: tr.returnFindSaleSubtitle

// Error state:
title: 'Search failed'
subtitle: state.errorMessage ?? 'Please try again'
→ title: tr.returnSearchFailed
  subtitle: state.errorMessage ?? context.tr.retry

// No results:
title: 'No sales found'
subtitle: 'Try a different receipt number or amount'
→ title: tr.returnNoSalesFound, subtitle: tr.returnNoSalesSubtitle
```

- [ ] **Step 4: Migrate `lib/features/returns/presentation/widgets/return_success_sheet.dart`**

Add import. Replace:
```dart
content: Text('Reference copied')     → content: Text(context.tr.refCopied)
label: const Text('Share return receipt via WhatsApp')
  → label: Text(context.tr.shareReturnWhatsApp)
child: const Text('Done')   → child: Text(context.tr.done)
```

- [ ] **Step 5: Migrate `lib/features/sales_history/presentation/widgets/sale_app_bar.dart`**

Add import. Replace:
```dart
Text('AMANAPOS', ...)       → Text(tr.amanaPosLabel, ...)
Text('Sales history', ...)  → Text(tr.salesHistoryTitle, ...)
```

- [ ] **Step 6: Migrate `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart`**

Add import. Replace:
```dart
content: const Text('Reference copied')          → content: Text(context.tr.refCopied)
content: const Text('Failed to generate receipt PDF')
  → content: Text(context.tr.saleReceiptFailure)
label: const Text('Return items from this sale') → label: Text(context.tr.returnItemsAction)
```

- [ ] **Step 7: Migrate `lib/features/sales_history/presentation/widgets/sale_footer.dart`**

Add import. Replace:
```dart
Text('All sales loaded', ...)  → Text(tr.allSalesLoaded, ...)
```

- [ ] **Step 8: Migrate `lib/features/sales_history/presentation/widgets/sale_error_view.dart`**

Add import. Replace:
```dart
Text('Could not load sales', ...)  → Text(tr.salesCouldNotLoad, ...)
label: const Text('Retry')         → label: Text(tr.retry)
```

- [ ] **Step 9: Migrate `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`**

Add import. Replace:
```dart
content: Text('Receipt number copied')
  → content: Text(context.tr.receiptCopied)

isOffline ? 'Saved offline' : 'Sale complete!'
  → isOffline ? context.tr.savedOffline : context.tr.saleComplete

'Tap to copy'           → context.tr.tapToCopy
Text('Total paid', ...) → Text(context.tr.totalPaid, ...)
label: const Text('Share via WhatsApp')
  → label: Text(context.tr.shareViaWhatsApp)
label: Text('Share via...', ...)
  → label: Text(context.tr.shareVia, ...)
child: const Text('New sale')   → child: Text(context.tr.newSale)
```

Note: `'Real receipt number will be assigned once synced.'` at line 223 is a technical note — leave it in English (not primary UX text, shown as a hint below a field).

- [ ] **Step 10: Analyze and commit**

```bash
flutter analyze lib/features/returns/ lib/features/sales_history/ lib/features/pos/presentation/widgets/sale_receipt_sheet.dart
git add lib/l10n/ lib/features/returns/ lib/features/sales_history/ \
  lib/features/pos/presentation/widgets/sale_receipt_sheet.dart
git commit -m "feat(l10n): migrate returns and sales history strings"
```

---

### Task 9: ARB batch 8 — Notifications + Main Screen

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/notification/presentation/notifications_screen.dart`
- Modify: `lib/features/main_screen/presentation/widgets/pos_app_bar.dart`
- Modify: `lib/features/main_screen/presentation/widgets/more_footer.dart`
- Modify: `lib/features/main_screen/presentation/widgets/today_cards.dart`

- [ ] **Step 1: Append Task 9 keys to both ARB files and run gen-l10n**

Add all 13 notification/main-screen keys (including the parameterized `viewPendingCount`) from the ARB Key Reference.

**Important:** The `@viewPendingCount` metadata entry must appear immediately after `viewPendingCount` in the ARB file:
```json
"viewPendingCount": "View {count} pending",
"@viewPendingCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/notification/presentation/notifications_screen.dart`**

Add import. In `_buildAppBar`, replace:
```dart
// Find the AppBar title — likely a Text with "Notifications" or similar
// If the current appBar has a hardcoded title, replace it:
Text('Notifications', ...)  → Text(tr.notificationsTitle, ...)
```

Also in the error view passed to `NotificationErrorView`:
```dart
message: state.error ?? 'Something went wrong'
  → message: state.error ?? tr.somethingWentWrong
```

- [ ] **Step 3: Migrate `lib/features/main_screen/presentation/widgets/pos_app_bar.dart`**

Add import. Replace the six status chip labels (lines ~448–482):
```dart
label: 'OFFLINE'      → label: tr.posStatusOffline
label: 'OFFLINE'      → label: tr.posStatusOffline  (second occurrence)
label: 'SYNC ISSUE'   → label: tr.posStatusSyncIssue
label: 'PENDING'      → label: tr.posStatusPending
label: 'SYNCING'      → label: tr.posStatusSyncing
label: 'SYNCED'       → label: tr.posStatusSynced
```

These are `ChipLabel` or similar widget — replace the string argument in each case.

- [ ] **Step 4: Migrate `lib/features/main_screen/presentation/widgets/more_footer.dart`**

Add import. Replace the pending count label using the parameterized key:
```dart
// BEFORE (line ~93):
label: Text(
  'View ${state.pendingSalesCount} pending',
  ...
),

// AFTER:
label: Text(
  context.tr.viewPendingCount(state.pendingSalesCount),
  ...
),
```

Replace the clear-data dialog:
```dart
title: const Text('Clear local data?')  → title: Text(context.tr.clearLocalDataTitle)
child: const Text('Cancel')             → child: Text(context.tr.cancel)
child: const Text('Clear')              → child: Text(context.tr.delete)
```

Note: `'Local data cleared.'` and `'Failed: $e'` are in SnackBar content — replace:
```dart
const SnackBar(content: Text('Local data cleared.'))
  → SnackBar(content: Text(context.tr.localDataCleared))
```

- [ ] **Step 5: Migrate `lib/features/main_screen/presentation/widgets/today_cards.dart`**

Add import. Replace the two chip labels:
```dart
label: 'SALES'  → label: tr.salesChipLabel
label: 'AVG'    → label: tr.avgChipLabel
```

Both at lines ~163/168 and ~309.

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze lib/features/notification/ lib/features/main_screen/presentation/widgets/
git add lib/l10n/ lib/features/notification/ lib/features/main_screen/presentation/widgets/
git commit -m "feat(l10n): migrate notifications and main screen strings"
```

---

### Task 10: ARB batch 9 — Inventory feature

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/inventory/presentation/expiry_alerts_screen.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/premium_hero_header.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/quick_actions_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/health_ring_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/inbound_velocity_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/expiry_timeline_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/recent_receipts_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/vendor_board_card.dart`
- Modify: `lib/features/inventory/presentation/premium/widgets/restock_queue_card.dart`
- Modify: `lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart`
- Modify: `lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart`
- Modify: `lib/features/inventory/presentation/widgets/stock_action_sheet.dart`

- [ ] **Step 1: Append Task 10 keys to both ARB files and run gen-l10n**

Add all 38 inventory keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/inventory/presentation/expiry_alerts_screen.dart`**

Add import. Replace the two filter chip labels (lines ~90, 122):
```dart
label: 'Expired'        → label: tr.invExpiryExpired
label: 'Expiring Soon'  → label: tr.invExpiryExpiringSoon
```

Replace Retry button label (line ~331):
```dart
label: const Text('Retry')  → label: Text(tr.retry)
```

- [ ] **Step 3: Migrate `lib/features/inventory/presentation/premium/widgets/premium_hero_header.dart`**

Add import. Replace the four hero stat card titles (lines ~352, 360, 370, 378) and action button labels (lines ~269, 274):
```dart
label: 'Export'             → label: tr.invHeroExport
label: 'Scan'               → label: tr.invHeroScan
title: 'Inventory Health'   → title: tr.invInventoryHealth
title: 'Needs Restock'      → title: tr.invNeedsRestock
title: 'Inbound This Month' → title: tr.invInboundThisMonth
title: 'Expiring ≤30 days'  → title: tr.invExpiringDays
```

- [ ] **Step 4: Migrate `lib/features/inventory/presentation/premium/widgets/quick_actions_card.dart`**

Add import. Replace:
```dart
title: 'Quick Actions'  → title: tr.invQuickActionsTitle
label: 'Receive'        → label: tr.invReceive
label: 'Stock'          → label: tr.invStockAction
label: 'Vendors'        → label: tr.invVendors
label: 'Expiry'         → label: tr.invExpiry
```

- [ ] **Step 5: Migrate health_ring_card, inbound_velocity_card, expiry_timeline_card, recent_receipts_card, vendor_board_card, restock_queue_card**

Each of these bento cards has a `title:` field passed to `CardHeader`. Replace:
```dart
// health_ring_card.dart:
title: 'Health Ring'        → title: tr.invHealthRingTitle
label: 'Healthy'            → label: tr.invHealthy
label: 'Low'                → label: tr.invLow
label: 'Out'                → label: tr.invOut

// inbound_velocity_card.dart:
title: 'Inbound Velocity'   → title: tr.invInboundVelocityTitle

// expiry_timeline_card.dart:
title: 'Expiry Timeline'    → title: tr.invExpiryTimelineTitle

// recent_receipts_card.dart:
title: 'Recent Receipts'    → title: tr.invRecentReceiptsTitle

// vendor_board_card.dart:
title: 'Vendor Board'       → title: tr.invVendorBoardTitle

// restock_queue_card.dart:
title: 'Restock Queue'      → title: tr.invRestockQueueTitle
```

- [ ] **Step 6: Migrate `lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart`**

Add import. Replace:
```dart
// SnackBar content (line ~51):
const SnackBar(content: Text('Vendor saved'))
  → SnackBar(content: Text(context.tr.invVendorSaved))

// Error SnackBar content (line ~56):
content: Text(state.submitError ?? 'Failed to save vendor')
  → content: Text(state.submitError ?? context.tr.invVendorFailed)

// Add button label (line ~101):
label: const Text('Add')  → label: Text(tr.add)

// Empty state text (line ~142):
child: const Text('Add your first vendor')
  → child: Text(tr.invAddFirstVendor)

// Context menu actions (lines ~213, 217):
child: Text('Edit')        → child: Text(tr.edit)
child: Text('Deactivate')  → child: Text(tr.invVendorDeactivate)
```

- [ ] **Step 7: Migrate `lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart`**

Add import. Replace:
```dart
// Vendor dropdown hint (line ~519):
hint: const Text('Select vendor')  → hint: Text(tr.invSelectVendor)

// Add row button (line ~591):
label: const Text('Add Row')  → label: Text(tr.invAddRow)
```

Note: `altArrowDown` at line 776 — leave as plain Icon (vertical, no RTL flip needed).
Note: `altArrowRight` at line 1135 — this will be handled in Task 12 (RTL pass).

- [ ] **Step 8: Migrate `lib/features/inventory/presentation/widgets/stock_action_sheet.dart`**

Add import. This sheet has three modes (Add In, Adjust, Transfer). Replace:
```dart
// Tab labels (lines ~329, 336, 343):
label: 'Add In'    → label: tr.invAddIn
label: 'Adjust'    → label: tr.invAdjust
label: 'Transfer'  → label: tr.invTransfer

// Add In mode fields:
FieldLabel(label: 'Movement Type', required: true) → FieldLabel(label: tr.invMovementType, required: true)
FieldLabel(label: 'Quantity', required: true)      → FieldLabel(label: tr.invFieldQuantity, required: true)
FieldLabel(label: 'Reference')                     → FieldLabel(label: tr.invFieldReference)
label: 'Confirm Movement'                          → label: tr.invConfirmMovement

// Adjust mode fields:
FieldLabel(label: 'New Quantity', required: true)  → FieldLabel(label: tr.invFieldNewQuantity, required: true)
FieldLabel(label: 'Notes')                         → FieldLabel(label: tr.invFieldNotes)
label: 'Adjust Stock'                              → label: tr.invAdjustStock

// Transfer mode fields:
FieldLabel(label: 'Transfer To', required: true)       → FieldLabel(label: tr.invTransferTo, required: true)
FieldLabel(label: 'Quantity to Transfer', required: true)
  → FieldLabel(label: tr.invQtyToTransfer, required: true)
label: 'Transfer Stock'                                → label: tr.invTransferStock
```

- [ ] **Step 9: Analyze and commit**

```bash
flutter analyze lib/features/inventory/presentation/
git add lib/l10n/ lib/features/inventory/presentation/
git commit -m "feat(l10n): migrate inventory feature strings"
```

---

### Task 11: ARB batch 10 — Business workspace

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Modify: `lib/features/business/presentation/business_detail_screen.dart`
- Modify: `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart`
- Modify: `lib/features/business/presentation/widgets/add_business_sheet.dart`
- Modify: `lib/features/business/presentation/widgets/edit_business_sheet.dart`
- Modify: `lib/features/business/presentation/widgets/deactivate_business_sheet.dart`
- Modify: `lib/features/business/presentation/widgets/info_section.dart`
- Modify: `lib/features/business/presentation/widgets/shop/add_shop_sheet.dart`
- Modify: `lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart`
- Modify: `lib/features/business/presentation/widgets/shop/shop_quick_stats.dart`
- Modify: `lib/features/business/presentation/fancy_business_bottom_sheet.dart`
- Modify: `lib/features/business/presentation/shop_management_screen.dart`

- [ ] **Step 1: Append Task 11 keys to both ARB files and run gen-l10n**

Add all 25 business keys from the ARB Key Reference.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Migrate `lib/features/business/presentation/business_detail_screen.dart`**

Add import. Replace:
```dart
title: 'Business Information'       → title: tr.bizInfoTitle
subtitle: 'Basic profile and contact details'  → subtitle: tr.bizInfoSubtitle
```

- [ ] **Step 3: Migrate `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart`**

Add import. Replace:
```dart
// Section header (line ~97):
title: 'MANAGE'  → title: tr.bizManageLabel

// Stat tiles (lines ~120–149):
title: 'Shops'
subtitle: shopCount == 1 ? 'Active branch' : 'Active branches'
→ title: tr.bizShopsTitle
  subtitle: shopCount == 1 ? tr.bizActiveBranch : tr.bizActiveBranches

title: 'Products'
subtitle: productCount == 1 ? 'Products item' : 'Products items'
→ title: tr.addProduct   // reuse existing key
  subtitle: productCount == 1 ? tr.bizProductsItem : tr.bizProductsItems

title: 'Cashiers'
subtitle: cashierCount == 1 ? 'User' : 'Users'
→ title: tr.settingsCashiers  // reuse existing key
  subtitle: cashierCount == 1 ? tr.bizUserSingular : tr.bizUserPlural

title: 'Reports'
subtitle: 'Browse and search all transactions'
→ title: tr.navReports  // reuse existing key
  subtitle: tr.bizReportSubtitle
```

- [ ] **Step 4: Migrate business sheets**

For each of `add_business_sheet.dart` and `edit_business_sheet.dart`:
```dart
FieldLabel(label: 'Business Name', required: true) → FieldLabel(label: tr.bizFieldBusinessName, required: true)
FieldLabel(label: 'Address')   → FieldLabel(label: tr.bizFieldAddress)
FieldLabel(label: 'Phone')     → FieldLabel(label: tr.bizFieldPhone)
FieldLabel(label: 'Email')     → FieldLabel(label: tr.bizFieldEmail)
```

For `deactivate_business_sheet.dart`:
```dart
title: 'Deactivate Business?'  → title: tr.bizDeactivateTitle
```

- [ ] **Step 5: Migrate `lib/features/business/presentation/widgets/info_section.dart`**

Add import. Replace:
```dart
label: 'Status'   → label: tr.bizStatusLabel
label: 'Address'  → label: tr.bizAddressLabel
label: 'Phone'    → label: tr.bizPhoneLabel
label: 'Email'    → label: tr.bizEmailLabel
label: 'Shops'    → label: tr.bizShopsLabel
```

- [ ] **Step 6: Migrate shop sheets and stats**

For `add_shop_sheet.dart` and `edit_shop_sheet.dart`:
```dart
FieldLabel(label: 'Shop Name', required: true)  → FieldLabel(label: tr.bizFieldShopName, required: true)
FieldLabel(label: 'Address')  → FieldLabel(label: tr.bizFieldAddress)
FieldLabel(label: 'Phone')    → FieldLabel(label: tr.bizFieldPhone)
```

For `shop_quick_stats.dart`:
```dart
label: 'Total Shops'  → label: tr.shopStatTotalShops
label: 'Active'       → label: tr.shopStatActive
label: 'Inactive'     → label: tr.shopStatInactive
```

- [ ] **Step 7: Migrate `lib/features/business/presentation/fancy_business_bottom_sheet.dart`**

Replace:
```dart
label: const Text('Create My Business')  → label: Text(tr.bizCreateMyBusiness)
```

- [ ] **Step 8: Migrate `lib/features/business/presentation/shop_management_screen.dart`**

Replace:
```dart
label: const Text('Add First Shop')  → label: Text(tr.bizAddFirstShop)
```

- [ ] **Step 9: Analyze and commit**

```bash
flutter analyze lib/features/business/presentation/
git add lib/l10n/ lib/features/business/presentation/
git commit -m "feat(l10n): migrate business workspace strings"
```

---

### Task 12: RTL DirectionalIcon replacement pass

**Goal:** Replace every `Icon(SolarIconsOutline.altArrowLeft, ...)` and `Icon(SolarIconsOutline.altArrowRight, ...)` used as navigation/chevron arrows with `DirectionalIcon(icon: ..., flipInRtl: true, ...)`. Do NOT change `altArrowUp`/`altArrowDown` (vertical — no RTL flip needed).

**Files to modify** (14 files):

| File | Line(s) | Icon | Purpose |
|------|---------|------|---------|
| `lib/widgets/back_button.dart` | 27 | altArrowLeft | back |
| `lib/features/settings/presentation/settings_screen.dart` | 160 | altArrowLeft | back nav |
| `lib/features/settings/presentation/settings_screen.dart` | 466 | altArrowRight | row chevron |
| `lib/features/settings/presentation/widgets/settings_action_tile.dart` | 214 | altArrowRight | row chevron |
| `lib/features/products/presentation/widgets/product_details/product_detail_app_bar_view.dart` | 83 | altArrowLeft | back |
| `lib/features/category/presentation/widgets/category_list.dart` | 183 | altArrowRight | row chevron |
| `lib/features/category/presentation/widgets/category_app_bar.dart` | 58 | altArrowLeft | back |
| `lib/features/notification/presentation/notifications_screen.dart` | 260 | altArrowLeft | back |
| `lib/features/pos/presentation/widgets/pos_sales_caption.dart` | 75 | altArrowRight | forward |
| `lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart` | 1135 | altArrowRight | row chevron |
| `lib/features/inventory/presentation/widgets/inbound_receiving_sheet.dart` | 1959, 2054 | altArrowRight | row chevron |
| `lib/features/inventory/presentation/widgets/add_stock_product_sheet.dart` | 696 | altArrowRight | row chevron |
| `lib/features/users/presentation/user_detail_screen.dart` | 105 | altArrowLeft | back |
| `lib/features/users/presentation/widgets/user_list.dart` | 155 | altArrowRight | row chevron |
| `lib/features/users/presentation/users_screen.dart` | 56 | altArrowLeft | back |
| `lib/features/main_screen/presentation/widgets/more_action_row.dart` | 76 | altArrowRight | row chevron |

- [ ] **Step 1: Add import to each file and replace Icon with DirectionalIcon**

For **every file** in the list above, add the import:
```dart
import 'package:amana_pos/widgets/directional_icon.dart';
```

Then replace the matching `Icon(...)` call. The pattern is always the same:

```dart
// BEFORE (example — back arrow in AppBar):
Icon(
  SolarIconsOutline.altArrowLeft,
  color: colors.textPrimary,
)

// AFTER:
DirectionalIcon(
  icon: SolarIconsOutline.altArrowLeft,
  flipInRtl: true,
  color: colors.textPrimary,
)
```

```dart
// BEFORE (example — row chevron):
Icon(
  SolarIconsOutline.altArrowRight,
  size: 18,
  color: colors.textHint,
)

// AFTER:
DirectionalIcon(
  icon: SolarIconsOutline.altArrowRight,
  flipInRtl: true,
  size: 18,
  color: colors.textHint,
)
```

Apply the same substitution pattern to **every occurrence listed above**. The `flipInRtl: true` argument is always set — the whole point of this pass is that these icons DO flip in RTL.

Do NOT change:
- `SolarIconsOutline.altArrowDown` (dropdown indicators — vertical, no flip)
- `SolarIconsOutline.altArrowUp` (cart peek — vertical, no flip)
- `SolarIconsOutline.roundArrowLeftUp` (returns icon — semantic icon, not navigation)
- `Icons.arrow_back_ios_new_rounded` in `login_screen.dart` — Flutter material icon, already auto-mirrors in RTL

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/widgets/directional_icon.dart \
  lib/features/settings/ \
  lib/features/products/ \
  lib/features/category/ \
  lib/features/notification/ \
  lib/features/pos/presentation/widgets/pos_sales_caption.dart \
  lib/features/inventory/ \
  lib/features/users/ \
  lib/features/main_screen/presentation/widgets/more_action_row.dart \
  lib/widgets/back_button.dart
```

Expected: No new errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/directional_icon.dart \
  lib/widgets/back_button.dart \
  lib/features/settings/presentation/ \
  lib/features/products/presentation/ \
  lib/features/category/presentation/ \
  lib/features/notification/presentation/ \
  lib/features/pos/presentation/widgets/pos_sales_caption.dart \
  lib/features/inventory/presentation/ \
  lib/features/users/presentation/ \
  lib/features/main_screen/presentation/widgets/more_action_row.dart
git commit -m "feat(l10n): replace directional Solar icons with DirectionalIcon for RTL support"
```

---

### Task 13: Final gen-l10n, full analyze, and smoke test

- [ ] **Step 1: Regenerate all localization files**

```bash
cd /Users/almogdadjabir/StudioProjects/amana_pos && flutter gen-l10n
```

Expected: No errors. All ARB keys reflected in generated classes.

- [ ] **Step 2: Run full analyzer**

```bash
flutter analyze --no-pub 2>&1 | grep -v "^Analyzing\|^ *info\|unnecessary_underscores\|deprecated_member_use" | head -50
```

Expected: Zero new errors from localization changes. Only pre-existing warnings acceptable.

- [ ] **Step 3: Smoke test in Arabic**

In Settings → Language, switch to Arabic. Verify:
- Login screen: welcome text, OTP text, buttons are in Arabic
- Bottom nav labels are in Arabic
- Settings screen section headers, row labels are in Arabic
- Theme picker options are in Arabic
- POS: "الكل" category chip, search hint in Arabic
- Back arrows (altArrowLeft → rendered as →) in Arabic layout
- Chevron arrows (altArrowRight → rendered as ←) in Arabic layout
- Bento inventory cards show Arabic titles
- Business workspace shows Arabic section labels

Kill and relaunch — Arabic persists.

Switch back to English — everything restores correctly.

- [ ] **Step 4: Commit generated files**

```bash
git add lib/l10n/app_localizations*.dart
git commit -m "chore(l10n): regenerate localization files after full-app string migration"
```

---

## Self-Review

### Spec coverage check

| Requirement | Task |
|-------------|------|
| Login + OTP strings | Task 2 |
| Settings sheets (theme, profile, password, bankak) | Task 2 |
| POS screen strings | Task 3 |
| Products feature | Task 4 |
| Categories feature | Task 5 |
| Users/Cashiers feature | Task 6 |
| Customers feature | Task 7 |
| Returns + Sales History | Task 8 |
| Notifications + Main Screen chips | Task 9 |
| Inventory (basic + premium) | Task 10 |
| Business workspace | Task 11 |
| DirectionalIcon widget for RTL arrows | Task 1 |
| RTL arrow replacement across 14+ files | Task 12 |
| Final verify + smoke test | Task 13 |

### Placeholder scan

No TBDs or TODOs in this plan. Every step has explicit code.

### Known omissions (intentional scope decisions)

- `lib/features/splash/presentation/splash_screen.dart` — The splash screen shows `'أمانة'` (Arabic text hardcoded intentionally as the brand name) and `'POINT  OF  SALE'` (intentional English brand tagline with letter-spacing). These are branding elements, not UI labels — leave as-is.
- `lib/features/registration/presentation/registration_screen.dart` — Stub screen (`'Registration'` and `'Registration Screen'`). Not a live screen — skip.
- `lib/features/sales_history/services/sale_receipt_pdf_service.dart` — PDF document generation; column headers like `'RECEIPT'`, `'DATE'`, `'PAYMENT'` are print-layout labels. Skip for now.
- `lib/features/main_screen/data/feature_config.dart` — `kFeatureConfigs` const data is never consumed by any widget call (MoreActionRow is defined but never called). Dead code — skip.
- `lib/features/business/presentation/widgets/feature_slider.dart` — Onboarding feature slider text. Not localized in this pass — scope creep risk.
- Form field placeholder text (`hint: 'Pepsi 330ml'`, `'Sara Ali'`, etc.) — These are example hints for form fields, not primary UI labels. Left in English to avoid confusion with brand/locale-specific examples.
