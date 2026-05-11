# Code Conventions

Read this before touching any file.

## Non-Negotiable Rules

1. **Never change code before being asked to.** Read, understand, then wait for the instruction.
2. **After every change, state exactly what you changed and why.**
3. **Match the existing style.** Copy naming, structure, and patterns from the surrounding code — do not introduce your own.
4. **Do not add packages.** Use what is already imported.
5. **Test any added code mentally** — trace the event → handler → emit → builder path before writing.

## Bloc Conventions

### Part files

State and event files use `part of`:
```dart
// navigation_state.dart
part of 'navigation_bloc.dart';

// navigation_event.dart  
part of 'navigation_bloc.dart';
```

The bloc file has:
```dart
part 'navigation_event.dart';
part 'navigation_state.dart';
```

### Event naming

```
On<Noun><Verb>   → OnProductInitial, OnAddProduct, OnCategoryReset
<Noun><Verb>     → PosAddProduct, PosCheckoutSubmitted, NavigationFeatureSelected
Set<Noun>Event   → SetMenuOpenEvent
```

Pick the pattern already used in the bloc you are editing.

### State copyWith

All states use manual `copyWith`. Never use code generation.

Fields that need clearing (nullable) use a `clear<Field>` bool flag:
```dart
copyWith({
  String?  responseError,
  bool     clearResponseError = false,
}) {
  return MyState(
    responseError: clearResponseError ? null : responseError ?? this.responseError,
  );
}
```

### emit.isDone guard

Any `emit()` call that happens after an `await` must be guarded:
```dart
if (!emit.isDone) {
  emit(state.copyWith(...));
}
```

### unawaited

Fire-and-forget async calls use `unawaited()` (not just calling without await):
```dart
unawaited(_backgroundRefresh());
```

### Error handling pattern in handlers

```dart
try {
  // ... work
} catch (e) {
  if (emittedCachedData) {
    emit(state.copyWith(status: success, responseError: e.toString(), isFromCache: true));
    return;
  }
  if (!emit.isDone) {
    emit(state.copyWith(status: failure, responseError: e.toString()));
  }
}
```

Rule: if cached data was shown, never replace the UI with an error screen — keep the cache + set `responseError`.

## Repository Convention

All repository methods return `Either<String?, T>`.
- Left = error string (human-readable) or null.
- Right = success value.

Usage in blocs:
```dart
final response = await useCase.doSomething();

// Simple:
response.fold(
  (error) => emit(state.copyWith(submitStatus: failure, submitError: error)),
  (result) => emit(state.copyWith(submitStatus: success, ...)),
);

// With nullable check:
final error = response.getLeft().toNullable();
final result = response.getRight().toNullable();
if (error != null) { ... return; }
if (result == null) return;
```

## DI Convention

Use `getIt<SomeType>()` to resolve dependencies inside `providers.dart` and `dependencies_provider.dart`.

Blocs that are singletons (created once, live forever): `AuthBloc`, `OfflineStatusBloc`.
All other blocs are created fresh in `getProviders` — they are NOT in GetIt.

To add a dependency to an existing bloc:
1. Add field to the bloc class.
2. Add parameter to the bloc constructor.
3. Update the `BlocProvider(create: ...)` in `providers.dart`.
4. If the dependency itself needs registering, add to `DependenciesProvider.build()` in `dependencies_provider.dart`.

## Naming Conventions

| Thing | Pattern | Example |
|---|---|---|
| Bloc files | `<feature>_bloc.dart` | `product_bloc.dart` |
| Event classes | `On<Noun><Verb>` or `<Noun><Verb>` | `OnAddProduct`, `PosAddProduct` |
| State classes | `<Feature>State` | `ProductState` |
| Enums (status) | `<Feature>Status` | `ProductStatus`, `CategorySubmitStatus` |
| Use case classes | `<Feature>UseCase` | `CategoryUseCase` |
| Repo classes | `<Feature>Repository` | `CategoryRepository` |
| Repo impl | `<Feature>RepoImpl` | `CategoryRepoImpl` |
| DTOs (request) | `<Action><Feature>RequestDto` | `AddCategoryRequestDto` |
| DTOs (response) | `<Action><Feature>ResponseDto` | `AddCategoryResponseDto` |
| Data models | `<Feature>Data` | `CategoryData`, `ProductData` |

## UI Conventions

### Snackbars

```dart
GlobalSnackBar.show(message: 'Some message', isError: true);
GlobalSnackBar.show(message: 'Done', isInfo: true);
```

### Sheets

Always opened with a standalone function:
```dart
void showAddProductSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProductBloc>(),
      child: _AddProductSheet(...),
    ),
  );
}
```

Private widget class inside the same file: `_AddProductSheet`.

### BlocBuilder rebuild gates

Always add `buildWhen` to limit rebuilds:
```dart
BlocBuilder<MyBloc, MyState>(
  buildWhen: (prev, curr) =>
      prev.status != curr.status ||
      prev.someList != curr.someList,
  builder: (context, state) { ... },
)
```

### BlocListener in sheets

Sheets listen to `submitStatus` to know when to close:
```dart
BlocListener<ProductBloc, ProductState>(
  listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
  listener: (context, state) {
    if (state.submitStatus == ProductSubmitStatus.success) {
      Navigator.of(context).pop();
      GlobalSnackBar.show(message: '...', isInfo: true);
    }
    if (state.submitStatus == ProductSubmitStatus.failure) {
      GlobalSnackBar.show(message: state.submitError ?? 'Error', isError: true);
    }
  },
  child: ...,
)
```

## Theme / Styling

Colors: `context.appColors.<token>` (extension from `AppThemeColors`).
Text styles: `AppTextStyles.bs200/300/400/500/600(context).copyWith(...)`.
Spacing: `AppDims.s2 / s3 / s4 / s5 / s6` — never use raw numbers for padding/spacing.
Border radius tokens: `AppDims.rSm / rMd / rXl`.
Animation duration: `AppDims.fast`.

## File Header Comments

Significant files have a header comment matching this style:
```dart
// lib/path/to/file.dart
//
// One-line purpose.
// Additional context if needed.
```

Do not add AI-style verbose comments. Keep comments to the minimum needed.
