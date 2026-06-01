# Localization (EN + AR) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add English and Arabic localization using Flutter's official ARB/gen system, with RTL support, a `LocaleBloc` following the existing `ThemeBloc` pattern, language persistence via `CacheStorage`, and a settings UI that switches the whole app language instantly.

**Architecture:** Create `LocaleBloc` in `lib/common/locale_bloc/` — identical structure to `ThemeBloc` — registered globally in `getAppProviders`. `app.dart` wraps `MaterialApp` in `BlocBuilder<LocaleBloc>` and passes `locale` and `localizationsDelegates`. Settings screen gets a `LanguagePickerSheet` (modeled on `ThemePickerSheet`). No third-party localization package.

**Tech Stack:** `flutter_localizations` (SDK), `intl` (already in pubspec), ARB files, `flutter gen-l10n` code generation, `synthetic-package: false`.

---

## File Map

| Status | File | Purpose |
|--------|------|---------|
| CREATE | `l10n.yaml` | flutter gen-l10n config |
| CREATE | `lib/l10n/app_en.arb` | English strings |
| CREATE | `lib/l10n/app_ar.arb` | Arabic strings |
| GENERATE | `lib/l10n/app_localizations.dart` | Generated (do not edit) |
| GENERATE | `lib/l10n/app_localizations_en.dart` | Generated (do not edit) |
| GENERATE | `lib/l10n/app_localizations_ar.dart` | Generated (do not edit) |
| CREATE | `lib/common/locale_bloc/locale_bloc.dart` | Bloc + event + state (part files) |
| CREATE | `lib/common/locale_bloc/locale_event.dart` | Events (part of locale_bloc.dart) |
| CREATE | `lib/common/locale_bloc/locale_state.dart` | State (part of locale_bloc.dart) |
| CREATE | `lib/common/localization/app_localizations_extension.dart` | `context.tr` extension |
| CREATE | `lib/features/settings/presentation/widgets/language_picker_sheet.dart` | Language selection sheet |
| MODIFY | `pubspec.yaml` | Add `flutter_localizations`, `generate: true` |
| MODIFY | `lib/config/constants.dart` | Add `appLocale` key |
| MODIFY | `lib/common/services/local/local_storage.dart` | Add `appLocale` to `_fastKeys` |
| MODIFY | `lib/config/providers/providers.dart` | Register `LocaleBloc` |
| MODIFY | `lib/app.dart` | Add locale delegates + `LocaleBloc` builder |
| MODIFY | `lib/features/settings/presentation/settings_screen.dart` | Hook language row + migrate strings |
| MODIFY | `lib/features/main_screen/presentation/widgets/bottom_nav.dart` | Migrate nav labels |
| CREATE | `docs/localization.md` | Developer documentation |

---

### Task 1: pubspec.yaml — add flutter_localizations and generate flag

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `flutter_localizations` under `dependencies`**

In `pubspec.yaml`, add immediately after the `flutter:` SDK dependency line (keep `intl` where it is — it's already present):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
```

- [ ] **Step 2: Add `generate: true` to the `flutter:` section**

At the bottom of the `flutter:` section (before `assets:`), add:

```yaml
flutter:
  uses-material-design: true
  generate: true

  assets:
    - assets/icons/
```

- [ ] **Step 3: Verify pubspec.yaml compiles**

```bash
flutter pub get
```

Expected: Resolving dependencies… (no errors). `flutter_localizations` now available.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(l10n): add flutter_localizations and generate flag"
```

---

### Task 2: Create l10n.yaml

**Files:**
- Create: `l10n.yaml` (project root)

- [ ] **Step 1: Create the file**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/l10n
```

- [ ] **Step 2: Commit**

```bash
git add l10n.yaml
git commit -m "chore(l10n): add l10n.yaml config"
```

---

### Task 3: Create ARB files

**Files:**
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Create `lib/l10n/app_en.arb`**

```json
{
  "@@locale": "en",

  "navHome": "Home",
  "navProducts": "Products",
  "navSell": "Sell",
  "navInventory": "Inventory",
  "navReports": "Reports",
  "navSettings": "Settings",

  "save": "Save",
  "cancel": "Cancel",
  "edit": "Edit",
  "delete": "Delete",
  "close": "Close",
  "search": "Search",
  "confirm": "Confirm",
  "done": "Done",
  "add": "Add",
  "retry": "Retry",
  "signOut": "Sign out",
  "noData": "No data found",

  "settingsSectionManage": "MANAGE",
  "settingsSectionAccount": "ACCOUNT & SECURITY",
  "settingsSectionAppearance": "APPEARANCE",
  "settingsSectionSupport": "SUPPORT",

  "settingsCategories": "Categories",
  "settingsCategoriesSubtitle": "Organize products",
  "settingsCashiers": "Cashiers",
  "settingsCashiersSubtitle": "Staff access & shifts",
  "settingsCustomers": "Customers",
  "settingsCustomersSubtitle": "Profiles & loyalty",
  "settingsReturns": "Returns",
  "settingsReturnsSubtitle": "Process customer item returns",
  "settingsSalesHistory": "Sales history",
  "settingsSalesHistorySubtitle": "Browse and search all transactions",

  "settingsProfile": "Profile",
  "settingsBankakPayments": "Bankak Payments",
  "settingsPassword": "Password",
  "settingsPasswordSubtitle": "Change your account password",
  "settingsWhatsappSupport": "WhatsApp Support",
  "settingsLanguage": "Language",
  "settingsSignOut": "Sign out",

  "currentLanguageName": "English",

  "languagePickerTitle": "Language",
  "languagePickerSubtitle": "Choose your preferred language.",
  "languageEnglish": "English",
  "languageEnglishNative": "English (EN)",
  "languageArabic": "Arabic",
  "languageArabicNative": "العربية (AR)",

  "profileUpdatedSuccess": "Updated successfully",
  "profileUpdateFailed": "Failed to update",
  "passwordUpdatedSuccess": "Password updated",
  "passwordUpdateFailed": "Failed to update password",

  "logoutConfirmTitle": "Sign out",
  "logoutConfirmMessage": "Are you sure you want to sign out?",

  "themeLight": "Light",
  "themeDark": "Dark",
  "themeSystem": "System"
}
```

- [ ] **Step 2: Create `lib/l10n/app_ar.arb`**

```json
{
  "@@locale": "ar",

  "navHome": "الرئيسية",
  "navProducts": "المنتجات",
  "navSell": "بيع",
  "navInventory": "المخزون",
  "navReports": "التقارير",
  "navSettings": "الإعدادات",

  "save": "حفظ",
  "cancel": "إلغاء",
  "edit": "تعديل",
  "delete": "حذف",
  "close": "إغلاق",
  "search": "بحث",
  "confirm": "تأكيد",
  "done": "تم",
  "add": "إضافة",
  "retry": "إعادة المحاولة",
  "signOut": "تسجيل الخروج",
  "noData": "لا توجد بيانات",

  "settingsSectionManage": "الإدارة",
  "settingsSectionAccount": "الحساب والأمان",
  "settingsSectionAppearance": "المظهر",
  "settingsSectionSupport": "الدعم",

  "settingsCategories": "الفئات",
  "settingsCategoriesSubtitle": "تنظيم المنتجات",
  "settingsCashiers": "الكاشيرات",
  "settingsCashiersSubtitle": "صلاحيات الموظفين والمناوبات",
  "settingsCustomers": "العملاء",
  "settingsCustomersSubtitle": "الملفات الشخصية والولاء",
  "settingsReturns": "المرتجعات",
  "settingsReturnsSubtitle": "معالجة مرتجعات العملاء",
  "settingsSalesHistory": "سجل المبيعات",
  "settingsSalesHistorySubtitle": "استعراض وبحث في جميع المعاملات",

  "settingsProfile": "الملف الشخصي",
  "settingsBankakPayments": "مدفوعات بنكك",
  "settingsPassword": "كلمة المرور",
  "settingsPasswordSubtitle": "تغيير كلمة مرور حسابك",
  "settingsWhatsappSupport": "دعم واتساب",
  "settingsLanguage": "اللغة",
  "settingsSignOut": "تسجيل الخروج",

  "currentLanguageName": "العربية",

  "languagePickerTitle": "اللغة",
  "languagePickerSubtitle": "اختر لغتك المفضلة.",
  "languageEnglish": "الإنجليزية",
  "languageEnglishNative": "English (EN)",
  "languageArabic": "العربية",
  "languageArabicNative": "العربية (AR)",

  "profileUpdatedSuccess": "تم التحديث بنجاح",
  "profileUpdateFailed": "فشل التحديث",
  "passwordUpdatedSuccess": "تم تحديث كلمة المرور",
  "passwordUpdateFailed": "فشل تحديث كلمة المرور",

  "logoutConfirmTitle": "تسجيل الخروج",
  "logoutConfirmMessage": "هل أنت متأكد من تسجيل الخروج؟",

  "themeLight": "فاتح",
  "themeDark": "داكن",
  "themeSystem": "النظام"
}
```

- [ ] **Step 3: Run code generation**

```bash
flutter gen-l10n
```

Expected: Creates `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_ar.dart`. No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "chore(l10n): add English and Arabic ARB files + generated localizations"
```

---

### Task 4: Add locale cache key

**Files:**
- Modify: `lib/config/constants.dart`
- Modify: `lib/common/services/local/local_storage.dart`

- [ ] **Step 1: Add `appLocale` to Constants**

In `lib/config/constants.dart`, add after the existing constants:

```dart
class Constants {
  static const cachedProfile = 'cachedProfile';
  static const authToken = 'auth_token';
  static const refreshToken = 'refresh_token';
  static const isDarkTheme = 'is_dark_theme';
  static const appTheme = 'app_theme';
  static const isBigFontSize = 'is_big_font_size';
  static const appLocale = 'app_locale';          // ← add this line
  static bool isTablet = true;
  static const xTenantID = 'x_tenant_iD';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static ScreenMode? currentSelectedMode = ScreenMode.light;
}
```

- [ ] **Step 2: Add `appLocale` to `_fastKeys` in CacheStorage**

In `lib/common/services/local/local_storage.dart`, update the `_fastKeys` set:

```dart
const _fastKeys = {
  Constants.appTheme,
  Constants.appLocale,    // ← add this line
};
```

- [ ] **Step 3: Commit**

```bash
git add lib/config/constants.dart lib/common/services/local/local_storage.dart
git commit -m "chore(l10n): add appLocale cache key"
```

---

### Task 5: Create LocaleBloc

**Files:**
- Create: `lib/common/locale_bloc/locale_bloc.dart`
- Create: `lib/common/locale_bloc/locale_event.dart`
- Create: `lib/common/locale_bloc/locale_state.dart`

- [ ] **Step 1: Create `lib/common/locale_bloc/locale_event.dart`**

```dart
part of 'locale_bloc.dart';

class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

class OnLocaleLoaded extends LocaleEvent {
  final String languageCode;
  const OnLocaleLoaded({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}

class OnLocaleChanged extends LocaleEvent {
  final String languageCode;
  const OnLocaleChanged({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}
```

- [ ] **Step 2: Create `lib/common/locale_bloc/locale_state.dart`**

```dart
part of 'locale_bloc.dart';

class LocaleState extends Equatable {
  final Locale locale;
  final bool isLoaded;

  const LocaleState({
    this.locale = const Locale('en'),
    this.isLoaded = false,
  });

  factory LocaleState.initial() => const LocaleState();

  LocaleState copyWith({
    Locale? locale,
    bool? isLoaded,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [locale, isLoaded];
}
```

- [ ] **Step 3: Create `lib/common/locale_bloc/locale_bloc.dart`**

```dart
import 'dart:ui';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'locale_event.dart';
part 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final CacheStorage cacheStorage;

  LocaleBloc({required this.cacheStorage}) : super(LocaleState.initial()) {
    on<OnLocaleLoaded>(_onLocaleLoaded);
    on<OnLocaleChanged>(_onLocaleChanged);

    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await cacheStorage.getValue(Constants.appLocale);
    add(OnLocaleLoaded(languageCode: saved ?? 'en'));
  }

  void _onLocaleLoaded(OnLocaleLoaded event, Emitter<LocaleState> emit) {
    emit(state.copyWith(
      locale: Locale(event.languageCode),
      isLoaded: true,
    ));
  }

  Future<void> _onLocaleChanged(
      OnLocaleChanged event, Emitter<LocaleState> emit) async {
    await cacheStorage.save(Constants.appLocale, event.languageCode);
    emit(state.copyWith(locale: Locale(event.languageCode)));
  }
}
```

- [ ] **Step 4: Confirm the three files analyze clean**

```bash
flutter analyze lib/common/locale_bloc/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/common/locale_bloc/
git commit -m "feat(l10n): add LocaleBloc with CacheStorage persistence"
```

---

### Task 6: Create context extension

**Files:**
- Create: `lib/common/localization/app_localizations_extension.dart`

- [ ] **Step 1: Create the extension file**

```dart
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationX on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this)!;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/common/localization/app_localizations_extension.dart
git commit -m "feat(l10n): add context.tr extension"
```

---

### Task 7: Register LocaleBloc in providers and update app.dart

**Files:**
- Modify: `lib/config/providers/providers.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Add `LocaleBloc` to `getAppProviders` in `providers.dart`**

Add import at the top of `lib/config/providers/providers.dart`:

```dart
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
```

Add the provider immediately after `ThemeBloc` in the returned list:

```dart
BlocProvider<LocaleBloc>(
  create: (_) => LocaleBloc(
    cacheStorage: getIt<CacheStorage>(),
  ),
),
```

The full updated list (excerpt):

```dart
List<BlocProvider> getAppProviders(BuildContext context) {
  return [
    BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
    ),
    BlocProvider<ThemeBloc>(
      create: (_) => ThemeBloc(
        cacheStorage: getIt<CacheStorage>(),
      ),
    ),
    BlocProvider<LocaleBloc>(
      create: (_) => LocaleBloc(
        cacheStorage: getIt<CacheStorage>(),
      ),
    ),
    // … rest unchanged
  ];
}
```

- [ ] **Step 2: Update `lib/app.dart`**

Replace the full content of `lib/app.dart` with:

```dart
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/providers/providers.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_observer.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final AppRouter _router = AppRouter();
  static final APPRouterObserver _routeObserver = APPRouterObserver();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getAppProviders(context),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) =>
            previous.isDarkTheme != current.isDarkTheme ||
            previous.isBigFontSize != current.isBigFontSize,
        builder: (context, themeState) {
          return BlocBuilder<LocaleBloc, LocaleState>(
            buildWhen: (previous, current) =>
                previous.locale != current.locale,
            builder: (context, localeState) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Amana POS',
                navigatorKey: Constants.navigatorKey,
                navigatorObservers: [_routeObserver],
                initialRoute: RouteStrings.splash,
                onGenerateRoute: _router.onGenerateRoute,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.isDarkTheme
                    ? ThemeMode.dark
                    : ThemeMode.light,
                locale: localeState.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Verify app compiles and starts**

```bash
flutter analyze lib/app.dart lib/config/providers/providers.dart
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/config/providers/providers.dart
git commit -m "feat(l10n): wire LocaleBloc into MaterialApp with localization delegates"
```

---

### Task 8: Create LanguagePickerSheet

**Files:**
- Create: `lib/features/settings/presentation/widgets/language_picker_sheet.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppBottomSheet(
      title: tr.languagePickerTitle,
      subtitle: tr.languagePickerSubtitle,
      icon: SolarIconsOutline.global,
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          final current = state.locale.languageCode;
          return Column(
            children: [
              _LangOption(
                languageCode: 'en',
                current: current,
                title: tr.languageEnglish,
                subtitle: tr.languageEnglishNative,
                delay: 0,
              ),
              const SizedBox(height: AppDims.s3),
              _LangOption(
                languageCode: 'ar',
                current: current,
                title: tr.languageArabic,
                subtitle: tr.languageArabicNative,
                delay: 55,
              ),
              const SizedBox(height: AppDims.s2),
            ],
          );
        },
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String languageCode;
  final String current;
  final String title;
  final String subtitle;
  final int delay;

  const _LangOption({
    required this.languageCode,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = languageCode == current;

    return GestureDetector(
      onTap: () {
        context
            .read<LocaleBloc>()
            .add(OnLocaleChanged(languageCode: languageCode));
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.35)
                : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              child: Center(
                child: Text(
                  languageCode == 'ar' ? 'ع' : 'A',
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 240.ms)
        .slideY(begin: 0.06, end: 0, duration: 240.ms, curve: Curves.easeOut);
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/settings/presentation/widgets/language_picker_sheet.dart
```

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/widgets/language_picker_sheet.dart
git commit -m "feat(l10n): add LanguagePickerSheet"
```

---

### Task 9: Update settings_screen.dart

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Add imports at the top of `settings_screen.dart`**

Add these two imports (after existing imports):

```dart
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/presentation/widgets/language_picker_sheet.dart';
```

- [ ] **Step 2: Add `_openLanguageSheet` helper method to `SettingsScreen`**

Add this method alongside the other sheet helpers:

```dart
void _openLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<LocaleBloc>(),
      child: const LanguagePickerSheet(),
    ),
  );
}
```

- [ ] **Step 3: Replace hardcoded section labels with `context.tr`**

Find and replace in the `build` method. The four `_SectionLabel(...)` calls:

```dart
// BEFORE:
const _SectionLabel('MANAGE'),
const _SectionLabel('ACCOUNT & SECURITY'),
const _SectionLabel('APPEARANCE'),
const _SectionLabel('SUPPORT'),

// AFTER (remove const, use tr):
_SectionLabel(tr.settingsSectionManage),
_SectionLabel(tr.settingsSectionAccount),
_SectionLabel(tr.settingsSectionAppearance),
_SectionLabel(tr.settingsSectionSupport),
```

Add `final tr = context.tr;` at the start of the `builder:` callback that contains the `Scaffold`.

- [ ] **Step 4: Replace hardcoded item titles and subtitles in MANAGE section**

```dart
// BEFORE:
_RowItem(
  icon: SolarIconsOutline.layersMinimalistic,
  title: 'Categories',
  subtitle: 'Organize products',
  ...
),
_RowItem(
  icon: SolarIconsOutline.userPlus,
  title: 'Cashiers',
  subtitle: 'Staff access & shifts',
  ...
),
_RowItem(
  icon: SolarIconsOutline.usersGroupTwoRounded,
  title: 'Customers',
  subtitle: 'Profiles & loyalty',
  ...
),
_RowItem(
  icon: SolarIconsOutline.roundArrowLeftUp,
  title: 'Returns',
  subtitle: 'Process customer item returns',
  ...
),
_RowItem(
  icon: SolarIconsOutline.notebook,
  title: 'Sales history',
  subtitle: 'Browse and search all transactions',
  ...
),

// AFTER:
_RowItem(
  icon: SolarIconsOutline.layersMinimalistic,
  title: tr.settingsCategories,
  subtitle: tr.settingsCategoriesSubtitle,
  ...
),
_RowItem(
  icon: SolarIconsOutline.userPlus,
  title: tr.settingsCashiers,
  subtitle: tr.settingsCashiersSubtitle,
  ...
),
_RowItem(
  icon: SolarIconsOutline.usersGroupTwoRounded,
  title: tr.settingsCustomers,
  subtitle: tr.settingsCustomersSubtitle,
  ...
),
_RowItem(
  icon: SolarIconsOutline.roundArrowLeftUp,
  title: tr.settingsReturns,
  subtitle: tr.settingsReturnsSubtitle,
  ...
),
_RowItem(
  icon: SolarIconsOutline.notebook,
  title: tr.settingsSalesHistory,
  subtitle: tr.settingsSalesHistorySubtitle,
  ...
),
```

- [ ] **Step 5: Replace ACCOUNT & SECURITY items**

```dart
// BEFORE:
_RowItem(icon: SolarIconsOutline.user, title: 'Profile', ...),
_RowItem(icon: SolarIconsOutline.card, title: 'Bankak Payments', ...),
_RowItem(icon: SolarIconsOutline.lockPassword, title: 'Password',
  subtitle: 'Change your account password', ...),

// AFTER:
_RowItem(icon: SolarIconsOutline.user, title: tr.settingsProfile, ...),
_RowItem(icon: SolarIconsOutline.card, title: tr.settingsBankakPayments, ...),
_RowItem(icon: SolarIconsOutline.lockPassword, title: tr.settingsPassword,
  subtitle: tr.settingsPasswordSubtitle, ...),
```

- [ ] **Step 6: Replace SUPPORT items and hook Language row**

```dart
// BEFORE:
_RowItem(
  icon: SolarIconsOutline.global,
  title: 'Language',
  subtitle: 'English',
  onTap: () {},
),

// AFTER (reads current language name from ARB, hooks up sheet):
BlocSelector<LocaleBloc, LocaleState, Locale>(
  selector: (s) => s.locale,
  builder: (context, locale) => _RowItem(
    icon: SolarIconsOutline.global,
    title: tr.settingsLanguage,
    subtitle: tr.currentLanguageName,
    onTap: () => _openLanguageSheet(context),
  ),
),
```

- [ ] **Step 7: Replace Sign out label**

```dart
// BEFORE:
label: Text('Sign out', ...),

// AFTER:
label: Text(tr.settingsSignOut, ...),
```

- [ ] **Step 8: Replace BlocListener messages in settings_screen.dart**

```dart
// BEFORE:
GlobalSnackBar.show(message: 'Updated successfully', isInfo: true);
GlobalSnackBar.show(message: state.submitError ?? 'Failed to update', isError: true);
GlobalSnackBar.show(message: 'Password updated', isInfo: true);
GlobalSnackBar.show(message: state.passwordError ?? 'Failed to update password', isError: true);

// AFTER (context is available in listener):
GlobalSnackBar.show(message: context.tr.profileUpdatedSuccess, isInfo: true);
GlobalSnackBar.show(message: state.submitError ?? context.tr.profileUpdateFailed, isError: true);
GlobalSnackBar.show(message: context.tr.passwordUpdatedSuccess, isInfo: true);
GlobalSnackBar.show(message: state.passwordError ?? context.tr.passwordUpdateFailed, isError: true);
```

- [ ] **Step 9: Analyze**

```bash
flutter analyze lib/features/settings/presentation/settings_screen.dart
```

Expected: No issues.

- [ ] **Step 10: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(l10n): migrate settings screen strings + hook language picker"
```

---

### Task 10: Migrate bottom_nav labels

**Files:**
- Modify: `lib/features/main_screen/presentation/widgets/bottom_nav.dart`

- [ ] **Step 1: Add imports**

Add at the top of `bottom_nav.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
```

- [ ] **Step 2: Update `buildTabs` to accept `BuildContext`**

Change the method signature from:

```dart
static List<NavTab> buildTabs(AppPermissions perms, {bool isPremium = false}) {
```

to:

```dart
static List<NavTab> buildTabs(
  BuildContext context,
  AppPermissions perms, {
  bool isPremium = false,
}) {
```

- [ ] **Step 3: Replace hardcoded labels with `context.tr` inside `buildTabs`**

Add `final tr = context.tr;` as the first line of `buildTabs`. Then replace every `label:` string:

```dart
static List<NavTab> buildTabs(
  BuildContext context,
  AppPermissions perms, {
  bool isPremium = false,
}) {
  final tr = context.tr;
  final tabs = <NavTab>[];

  if (perms.isOwner) {
    if (perms.canAccessBusiness) {
      tabs.add(NavTab(
        feature: AppFeature.business,
        icon: SolarIconsBold.shop,
        activeIcon: SolarIconsBold.shop,
        label: tr.navHome,
      ));
    }

    if (perms.canAccessProducts) {
      tabs.add(NavTab(
        feature: AppFeature.products,
        icon: SolarIconsOutline.bag5,
        activeIcon: SolarIconsOutline.bag5,
        label: tr.navProducts,
      ));
    }

    tabs.add(NavTab(
      feature: AppFeature.pos,
      icon: SolarIconsOutline.cartLarge_4,
      activeIcon: SolarIconsOutline.cartLarge,
      label: tr.navSell,
    ));

    // Replace all remaining label: '...' strings with tr.nav* equivalents
    // for Inventory (tr.navInventory), Reports (tr.navReports),
    // Settings (tr.navSettings) following the same pattern.
  }
  // ... (cashier tabs: Sell only — no label changes needed for non-owner path
  //      unless labels exist there too)
  return tabs;
}
```

- [ ] **Step 4: Update the call site in `BottomNav.build`**

Find where `buildTabs` is called and add `context`:

```dart
// BEFORE:
final tabs = buildTabs(state.permissions, isPremium: isPremium);

// AFTER:
final tabs = buildTabs(context, state.permissions, isPremium: isPremium);
```

Note: `NavTab` objects can no longer be `const` because labels come from `context.tr`. Remove `const` from each `NavTab(...)` call inside `buildTabs`.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/main_screen/presentation/widgets/bottom_nav.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/main_screen/presentation/widgets/bottom_nav.dart
git commit -m "feat(l10n): migrate bottom nav labels to localized strings"
```

---

### Task 11: Run full analyze and verify

- [ ] **Step 1: Run generation to ensure files are fresh**

```bash
flutter gen-l10n
```

Expected: No errors. Generated files updated.

- [ ] **Step 2: Run full analyze**

```bash
flutter analyze --no-pub 2>&1 | grep -v "^Analyzing\|^  info\|unnecessary_underscores\|deprecated_member_use" | head -40
```

Expected: Only pre-existing warnings (unrelated to l10n). Zero new errors.

- [ ] **Step 3: Hot restart the app (iOS or Android)**

Navigate to **Settings → Language**. Tap "Arabic". Verify:
- Entire app switches to Arabic strings immediately.
- App direction becomes RTL.
- Bottom nav labels are in Arabic.
- Settings section headers are in Arabic.

Tap "English". Verify the reverse.

Kill and relaunch the app. Verify the last selected language is restored.

- [ ] **Step 4: Commit generated files**

```bash
git add lib/l10n/app_localizations*.dart
git commit -m "chore(l10n): commit generated localization files"
```

---

### Task 12: Write developer documentation

**Files:**
- Create: `docs/localization.md`

- [ ] **Step 1: Create the file**

```markdown
# Localization

AmanaPOS uses Flutter's official ARB-based localization (`flutter_localizations` + `intl`). No third-party localization package is used.

## Adding a new string

1. Add the key to `lib/l10n/app_en.arb` (English value).
2. Add the same key to `lib/l10n/app_ar.arb` (Arabic value).
3. Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart`.
4. Use `context.tr.yourNewKey` in any widget.

Example:
```arb
// app_en.arb
"myNewLabel": "Hello"

// app_ar.arb  
"myNewLabel": "مرحبا"
```

```dart
Text(context.tr.myNewLabel)
```

## Adding a new language

1. Create `lib/l10n/app_XX.arb` where `XX` is the ISO language code (e.g., `fr` for French).
2. Add the locale to `AppLocalizations.supportedLocales` — this happens automatically when the ARB file is present and `flutter gen-l10n` is run.
3. Add a language option to `LanguagePickerSheet` in `lib/features/settings/presentation/widgets/language_picker_sheet.dart`.
4. Run `flutter gen-l10n`.

## How language persistence works

`LocaleBloc` (at `lib/common/locale_bloc/locale_bloc.dart`) manages the selected locale for the app's lifetime.

- On startup: reads `Constants.appLocale` key from `CacheStorage` (SharedPreferences fast path). Defaults to `'en'` if not set.
- On change: persists the new language code to `CacheStorage`, then emits a new `LocaleState` with the updated `Locale`.
- `app.dart` wraps `MaterialApp` in `BlocBuilder<LocaleBloc, LocaleState>` and passes `localeState.locale` to `MaterialApp.locale`. Flutter rebuilds the entire widget tree with the new locale, including RTL layout for Arabic.

## Where localization state lives

- **Bloc**: `lib/common/locale_bloc/locale_bloc.dart`
- **Registration**: `lib/config/providers/providers.dart` → `getAppProviders` (global, root-level)
- **Usage**: `context.tr.<key>` via the extension at `lib/common/localization/app_localizations_extension.dart`
- **Cache key**: `Constants.appLocale` → stored in SharedPreferences

## Rules

- Never use localized strings inside BLoC, use cases, repositories, or data sources.
- Never store localized strings in BLoC state — only IDs or error codes.
- Do not translate: API keys, route names, enum values, cache keys, backend payload keys, log messages.
```

- [ ] **Step 2: Commit**

```bash
git add docs/localization.md
git commit -m "docs(l10n): add localization developer guide"
```

---

## Self-Review

**Spec coverage check:**

| Requirement | Task |
|-------------|------|
| flutter_localizations + intl + generate:true + l10n.yaml | Task 1 + 2 |
| ARB files EN + AR | Task 3 |
| `context.tr` extension | Task 6 |
| LocaleBloc with CacheStorage persistence | Task 5 |
| Default English | LocaleBloc._loadLocale() defaults to 'en' |
| Register in getProviders | Task 7 |
| MaterialApp locale + delegates + supportedLocales | Task 7 |
| RTL on Arabic | Flutter handles automatically via MaterialApp.locale |
| Language selection in Settings (EN + AR) | Task 8 + 9 |
| Immediate switch + persist | OnLocaleChanged saves + emits |
| Migrate nav labels | Task 10 |
| Migrate settings strings | Task 9 |
| No localization in BLoC/repo | Enforced by design |
| localization.md | Task 12 |
| flutter analyze | Task 11 |

**Remaining hardcoded strings (second pass):**

The following screens still have hardcoded strings after this plan — they are noted here, not forgotten:
- `ThemePickerSheet` — 'Appearance', 'Light', 'Dark', 'System'
- `LoginScreen` — login form labels
- `SplashScreen` — app name / tagline
- `POS screens` — product/cart/checkout labels
- `EditProfileSheet`, `SetPasswordSheet`, `EditBankakSheet` — form labels
- `GlobalSnackBar` messages inside blocs (keep as API strings for now)

These require a second ARB pass after this plan ships.
