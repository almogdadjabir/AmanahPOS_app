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

1. Create `lib/l10n/app_XX.arb` where `XX` is the ISO 639-1 language code (e.g., `fr` for French).
2. Run `flutter gen-l10n` — the new language is automatically picked up.
3. Add a language option to `LanguagePickerSheet` in `lib/features/settings/presentation/widgets/language_picker_sheet.dart`.

## How language persistence works

`LocaleBloc` (`lib/common/locale_bloc/locale_bloc.dart`) manages the selected locale for the entire app lifetime.

- **On startup:** reads `Constants.appLocale` from `CacheStorage` (SharedPreferences fast path). Defaults to `'en'` if not set.
- **On change:** `OnLocaleChanged(languageCode: 'ar')` persists the code to `CacheStorage` and emits a new `LocaleState`.
- **app.dart** wraps `MaterialApp` in `BlocBuilder<LocaleBloc, LocaleState>` and sets `locale: localeState.locale`. Flutter rebuilds the full widget tree with the new locale, including RTL layout for Arabic.

## Where localization state lives

| What | Where |
|------|-------|
| Bloc | `lib/common/locale_bloc/locale_bloc.dart` |
| Registration | `lib/config/providers/providers.dart` → `getAppProviders` (root-level, global) |
| Extension | `lib/common/localization/app_localizations_extension.dart` |
| Cache key | `Constants.appLocale` → SharedPreferences |
| ARB strings | `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` |
| Generated code | `lib/l10n/app_localizations*.dart` (do not edit manually) |

## Rules

- **Never** use `context.tr` inside BLoC, use cases, repositories, or data sources.
- **Never** store localized strings in BLoC state — keep error codes or backend messages as-is.
- **Do not translate:** API keys, route names, enum values, cache keys, backend payload fields, log messages.

## Screens still needing a second pass

The following screens have hardcoded strings not yet migrated. Add them in the next localization pass:

- `ThemePickerSheet` — 'Appearance', 'Light', 'Dark', 'System'
- Login / splash screens
- POS screens (product names, cart, checkout labels)
- `EditProfileSheet`, `SetPasswordSheet`, `EditBankakSheet` — form labels
