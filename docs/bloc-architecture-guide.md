# Flutter BLoC Architecture Guide

> Based on the production architecture of AmanaPOS.
> Copy this into your own project as a reference — the patterns work for any domain.

---

## Stack

| Package | Role |
|---|---|
| `flutter_bloc` | BLoC implementation |
| `equatable` | Value equality for State & Event |
| `get_it` | Service locator / dependency injection |
| `fpdart` | `Either<String, T>` for typed error handling |
| `dio` | HTTP client |

---

## Folder Structure

One folder per feature. Every feature has exactly three layers.

```
lib/
├── config/
│   ├── providers/
│   │   └── feature_bloc_providers.dart   # BlocProvider factories per feature
│   └── router/
│       └── app_router.dart               # Wires providers to routes
├── core/                                 # Cross-cutting (network, offline, DI)
│   ├── api/
│   │   └── request_handler.dart          # Generic HTTP wrapper → Either<String,T>
│   └── network/
│       └── dio_client.dart
├── common/
│   └── auth_bloc/                        # App-wide singleton BLoC (lives in getIt)
│       ├── auth_bloc.dart
│       ├── auth_event.dart
│       └── auth_state.dart
├── utilities/
│   └── dependencies_provider.dart        # All getIt registrations in one place
└── features/
    └── login/                            # ← one folder per feature
        ├── data/
        │   ├── models/                   # DTOs (fromJson / toJson)
        │   │   └── login_request.dart
        │   └── repository_impl/
        │       └── login_repo_impl.dart  # Concrete HTTP implementation
        ├── domain/
        │   ├── repository/
        │   │   └── login_repository.dart # Abstract interface
        │   └── usecase/
        │       └── login_usecase.dart    # Thin orchestrator
        └── presentation/
            ├── bloc/
            │   ├── login_bloc.dart       # part 'login_event.dart'; part 'login_state.dart';
            │   ├── login_event.dart      # part of 'login_bloc.dart';
            │   └── login_state.dart      # part of 'login_bloc.dart';
            ├── login_screen.dart
            └── widgets/
                └── login_form.dart
```

---

## Layer 1 — Data

### Models (DTOs)

Pure Dart classes that serialize/deserialize JSON. No business logic.

```dart
class LoginRequest {
  final String phone;
  const LoginRequest({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class LoginResponse {
  final String? sessionId;
  const LoginResponse({this.sessionId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      LoginResponse(sessionId: json['session_id'] as String?);
}
```

### Repository Implementation

Takes a `RequestHandler` (the HTTP wrapper). Returns `Either<String, T>` —
left is an error message, right is the parsed response.

```dart
class LoginRepoImpl extends LoginRepository {
  LoginRepoImpl(this.requestHandler);
  final RequestHandler requestHandler;

  @override
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request) {
    return requestHandler.handlePostRequest(
      'api-public/v1/auth/login/otp/',
      (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }
}
```

`RequestHandler.handlePostRequest` handles HTTP, catches exceptions, and wraps
them into `Either`. You never write try/catch in repository implementations.

---

## Layer 2 — Domain

### Repository Interface

Abstract class — the contract. The BLoC only knows this, never the implementation.

```dart
abstract class LoginRepository {
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request);
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request);
  Future<Either<String?, bool>> logout(dynamic request);
}
```

### Use Case

A thin class that groups related repository methods and can hold cross-cutting
services (cache, other blocs). Not a factory or builder — just named method
delegation.

```dart
class LoginUseCase {
  final LoginRepository repository;
  final CacheStorage cacheStorage;

  LoginUseCase({
    required this.repository,
    required this.cacheStorage,
  });

  Future<Either<String?, LoginResponse>> userLogin(LoginRequest r) =>
      repository.userLogin(r);

  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest r) =>
      repository.otpVerify(r);
}
```

**Rule:** Use cases never emit, never call BLoCs. They are pure service objects.

---

## Layer 3 — Presentation / BLoC

Three files, all in `presentation/bloc/`. The event and state files use
`part of` so they share the BLoC's imports.

### Event

```dart
// login_event.dart
part of 'login_bloc.dart';

class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object?> get props => [];
}

class OnMobileChangedEvent extends LoginEvent {
  final String mobile;
  const OnMobileChangedEvent({required this.mobile});
}

class OnLoginSubmitEvent extends LoginEvent {}

class OnChangeOtpEvent extends LoginEvent {
  final String otpCode;
  const OnChangeOtpEvent({required this.otpCode});
}

class OnSubmitOtpEvent extends LoginEvent {}

class OnResendOtpEvent extends LoginEvent {
  const OnResendOtpEvent();
}

class OnResetEvent extends LoginEvent {
  final bool? isPhoneChange;
  const OnResetEvent({this.isPhoneChange});
}
```

**Rules:**
- Extend `Equatable`
- Use `On` prefix: `OnSubmitEvent`, `OnLoadEvent`, `OnChangedEvent`
- One event = one user intention. Never pass business logic as a callback.

### State

```dart
// login_state.dart
part of 'login_bloc.dart';

enum PageStatus { initial, loading, success, failure }

enum LoginStatus {
  form(0),
  otp(1),
  completed(2);

  final int page;
  const LoginStatus(this.page);
}

class LoginState extends Equatable {
  final PageStatus status;
  final LoginStatus loginStatus;
  final bool isLoading;
  final String? phoneNumber;
  final String? mobileError;
  final bool isMobileValid;
  final String? otp;
  final bool isPinMatched;
  final String? otpError;
  final int otpResendSeconds;

  const LoginState({
    this.status = PageStatus.initial,
    this.loginStatus = LoginStatus.form,
    this.isLoading = false,
    this.phoneNumber,
    this.mobileError,
    this.isMobileValid = false,
    this.otp,
    this.isPinMatched = false,
    this.otpError,
    this.otpResendSeconds = 45,
  });

  factory LoginState.initial() => const LoginState();

  // Use explicit boolean flags to clear nullable fields.
  // copyWith(mobileError: null) is ambiguous — did you want to clear it or skip it?
  LoginState copyWith({
    PageStatus? status,
    LoginStatus? loginStatus,
    bool? isLoading,
    String? phoneNumber,
    String? mobileError,
    bool clearMobileError = false,   // explicit clear flag pattern
    bool? isMobileValid,
    String? otp,
    bool? isPinMatched,
    String? otpError,
    bool clearOtpError = false,      // explicit clear flag pattern
    int? otpResendSeconds,
  }) {
    return LoginState(
      status: status ?? this.status,
      loginStatus: loginStatus ?? this.loginStatus,
      isLoading: isLoading ?? this.isLoading,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileError: clearMobileError ? null : (mobileError ?? this.mobileError),
      isMobileValid: isMobileValid ?? this.isMobileValid,
      otp: otp ?? this.otp,
      isPinMatched: isPinMatched ?? this.isPinMatched,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      otpResendSeconds: otpResendSeconds ?? this.otpResendSeconds,
    );
  }

  @override
  List<Object?> get props => [
    status, loginStatus, isLoading, phoneNumber,
    mobileError, isMobileValid, otp, isPinMatched,
    otpError, otpResendSeconds,
  ];
}
```

**Rules:**
- Always extend `Equatable` and implement `props`
- Always provide a `factory State.initial()` — use it in the BLoC constructor and reset handlers
- `copyWith` for nullable fields: add a `clearX = false` flag instead of relying on `null` passthrough
- State fields are `final`, state is immutable

### BLoC

```dart
// login_bloc.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
// ... feature imports

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase useCase;
  final CacheStorage cacheStorage;

  Timer? _resendTimer; // timers / subscriptions live here, cancelled in close()

  LoginBloc({
    required this.useCase,
    required this.cacheStorage,
  }) : super(LoginState.initial()) {
    on<OnMobileChangedEvent>(_onMobileChanged);
    on<OnLoginSubmitEvent>(_onLoginSubmit);
    on<OnChangeOtpEvent>(_onChangeOtp);
    on<OnSubmitOtpEvent>(_onSubmitOtp);
    on<OnResendOtpEvent>(_onResendOtp);
    on<OnResetEvent>(_onReset);
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel(); // always cancel timers in close()
    return super.close();
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onMobileChanged(
    OnMobileChangedEvent event,
    Emitter<LoginState> emit,
  ) {
    final digits = event.mobile.replaceAll(RegExp(r'\D'), '');
    emit(state.copyWith(
      phoneNumber: event.mobile,
      isMobileValid: digits.length == 9,
      clearMobileError: true,
    ));
  }

  Future<void> _onLoginSubmit(
    OnLoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMobileError: true));

    final result = await useCase.userLogin(
      LoginRequest(phone: '+249${state.phoneNumber}'),
    );

    if (emit.isDone) return; // always check after every await

    result.fold(
      (error) => emit(state.copyWith(
        isLoading: false,
        status: PageStatus.failure,
        mobileError: error,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        status: PageStatus.success,
        loginStatus: LoginStatus.otp,
      )),
    );
  }

  void _onChangeOtp(OnChangeOtpEvent event, Emitter<LoginState> emit) {
    emit(state.copyWith(otp: event.otpCode, clearOtpError: true));
    if (event.otpCode.length == 6) add(OnSubmitOtpEvent());
  }

  Future<void> _onSubmitOtp(
    OnSubmitOtpEvent event,
    Emitter<LoginState> emit,
  ) async {
    if ((state.otp ?? '').length < 6 || state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearOtpError: true));

    final result = await useCase.otpVerify(
      OtpVerifyRequest(phone: '+249${state.phoneNumber}', otp: state.otp!),
    );

    if (emit.isDone) return;

    result.fold(
      (error) => emit(state.copyWith(
        isLoading: false,
        status: PageStatus.failure,
        otpError: error,
        otp: '',
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        status: PageStatus.success,
        isPinMatched: true,
        loginStatus: LoginStatus.completed,
      )),
    );
  }

  Future<void> _onResendOtp(
    OnResendOtpEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearOtpError: true));
    await useCase.resendOtp();
    if (emit.isDone) return;
    _startResendTimer();
    emit(state.copyWith(isLoading: false, otpResendSeconds: 45));
  }

  void _onReset(OnResetEvent event, Emitter<LoginState> emit) {
    _resendTimer?.cancel();
    emit(LoginState.initial()); // use initial() to reset fully
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const _OtpTimerTickEvent());
    });
  }
}
```

**Rules:**
- Register all handlers in the constructor — never in a method called from outside
- One private method per event: `_onEventName(Event, Emitter)`
- Always `if (emit.isDone) return;` after every `await`
- Use `Either.fold` to handle success/failure — no nested `if (result.isLeft())`
- Timers and stream subscriptions: store as fields, cancel in `close()`
- Never call `getIt` inside handlers — inject everything in the constructor

---

## Dependency Injection — `get_it`

One file, one class, one static method. Registration order matters:
infrastructure → repositories → use cases → singleton BLoCs.

```dart
// lib/utilities/dependencies_provider.dart
final getIt = GetIt.instance;

class DependenciesProvider {
  DependenciesProvider._();

  static void build() {
    // 1. Infrastructure
    getIt.registerLazySingleton<Dio>(() => Dio());
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(baseUrl, dio: getIt<Dio>()),
    );
    getIt.registerLazySingleton<RequestHandler>(
      () => RequestHandler(getIt<DioClient>()),
    );
    getIt.registerLazySingleton<CacheStorage>(() => CacheStorage());

    // 2. Repositories (register against the abstract type)
    getIt.registerLazySingleton<LoginRepository>(
      () => LoginRepoImpl(getIt<RequestHandler>()),
    );

    // 3. Use cases
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(
        repository: getIt<LoginRepository>(),
        cacheStorage: getIt<CacheStorage>(),
      ),
    );

    // 4. App-wide singleton BLoCs ONLY
    // Feature BLoCs are NOT registered here — they live in FeatureBlocProviders
    getIt.registerLazySingleton<AuthBloc>(
      () => AuthBloc(useCase: getIt<LoginUseCase>()),
    );
  }

  static T provide<T extends Object>() => getIt.get<T>();
}
```

Call `DependenciesProvider.build()` at the top of `main()`, before `runApp`.

**Rules:**
- Register against the **abstract type**: `getIt<LoginRepository>()` not `getIt<LoginRepoImpl>()`
- `registerLazySingleton` for everything — created on first use, lives forever
- Only app-wide BLoCs (auth, offline status) go into `getIt`. Feature BLoCs do not.

---

## BLoC Provisioning — `FeatureBlocProviders`

A static factory class that wraps feature screens in their `BlocProvider`.
Called from the router, never from screens.

```dart
// lib/config/providers/feature_bloc_providers.dart

class FeatureBlocProviders {
  const FeatureBlocProviders._();

  // Single-BLoC feature
  static Widget login({required Widget child}) {
    return BlocProvider(
      create: (_) => LoginBloc(
        useCase: getIt<LoginUseCase>(),
        cacheStorage: getIt<CacheStorage>(),
      ),
      child: child,
    );
  }

  // Multi-BLoC feature
  static Widget inventory({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => InventoryBloc(useCase: getIt<InventoryUseCase>()),
        ),
        BlocProvider(
          create: (_) => StockLevelsBloc(useCase: getIt<InventoryUseCase>()),
        ),
      ],
      child: child,
    );
  }
}
```

```dart
// lib/config/router/app_router.dart — usage
GoRoute(
  path: '/login',
  builder: (_, __) => FeatureBlocProviders.login(
    child: const LoginScreen(),
  ),
),
```

**Why this pattern:**
- Screens have zero knowledge of how their BLoCs are constructed
- Easy to swap use cases in tests — mock the `getIt` registration before calling the factory
- Multi-BLoC features are explicit and readable in one place

---

## App-Wide Singleton BLoCs

BLoCs that live across the entire app (auth, offline/connectivity, sync) are:
1. Registered as `lazySingleton` in `getIt`
2. Provided once at the app root via `BlocProvider.value`

```dart
// In your MaterialApp / root widget
MultiBlocProvider(
  providers: [
    BlocProvider.value(value: getIt<AuthBloc>()),
    BlocProvider.value(value: getIt<OfflineStatusBloc>()),
  ],
  child: MaterialApp(...),
)
```

**`BlocProvider` vs `BlocProvider.value`:**
- `BlocProvider(create: ...)` — BLoC is owned and closed by the tree
- `BlocProvider.value(value: ...)` — BLoC is owned by `getIt`, tree just exposes it

Use `BlocProvider.value` for all singletons.

---

## Widget Consumption Patterns

### `BlocBuilder` — rebuild part of the UI

```dart
BlocBuilder<LoginBloc, LoginState>(
  // Always provide buildWhen — without it the widget rebuilds on every emission
  buildWhen: (prev, curr) => prev.isMobileValid != curr.isMobileValid,
  builder: (context, state) {
    return AppButton(
      label: 'Continue',
      onPressed: state.isMobileValid
          ? () => context.read<LoginBloc>().add(OnLoginSubmitEvent())
          : null,
    );
  },
)
```

### `BlocListener` — side effects only

```dart
BlocListener<LoginBloc, LoginState>(
  listenWhen: (prev, curr) => prev.status != curr.status,
  listener: (context, state) {
    if (state.status == PageStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.mobileError ?? 'Error')),
      );
    }
  },
  child: const LoginForm(),
)
```

Use for: navigation, snackbars, dialogs, analytics.
Never put UI rebuild logic here.

### `BlocConsumer` — rebuild + side effects together

```dart
BlocConsumer<LoginBloc, LoginState>(
  listenWhen: (prev, curr) => prev.loginStatus != curr.loginStatus,
  listener: (context, state) {
    if (state.loginStatus == LoginStatus.completed) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
  buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
  builder: (context, state) {
    return state.isLoading
        ? const CircularProgressIndicator()
        : const LoginForm();
  },
)
```

### `context.read` — fire and forget, no rebuild

```dart
// In a button handler — never call context.read inside build()
onTap: () => context.read<LoginBloc>().add(OnLoginSubmitEvent()),
```

### `context.select` — subscribe to a single field

```dart
// Rebuilds only when isLoading changes
final isLoading = context.select<LoginBloc, bool>(
  (bloc) => bloc.state.isLoading,
);
```

Use `context.select` for leaf widgets that only need one field — cheaper than
a full `BlocBuilder`.

---

## Error Handling — `Either<String, T>`

Repository methods return `Either<String?, T>` from `fpdart`.
Left = error message string. Right = success value.

```dart
// In the BLoC handler — use fold, not isLeft()/isRight()
final result = await useCase.userLogin(request);
if (emit.isDone) return;

result.fold(
  (errorMessage) => emit(state.copyWith(
    isLoading: false,
    status: PageStatus.failure,
    mobileError: errorMessage,
  )),
  (response) => emit(state.copyWith(
    isLoading: false,
    status: PageStatus.success,
    loginStatus: LoginStatus.otp,
  )),
);
```

The BLoC never catches HTTP exceptions — `RequestHandler` converts them all
into `Left(message)` before they reach the BLoC.

---

## Migration Cheat Sheet — Riverpod → BLoC

| Riverpod | BLoC equivalent |
|---|---|
| `StateNotifier` + `StateNotifierProvider` | `Bloc<Event, State>` + `BlocProvider` |
| `ref.read(provider)` | `context.read<MyBloc>()` |
| `ref.watch(provider)` | `BlocBuilder` or `context.select` |
| `ref.listen(provider, cb)` | `BlocListener` |
| `Provider` (dependency injection) | `getIt.registerLazySingleton` |
| `ProviderScope` at root | `MultiBlocProvider` at root |
| `AsyncValue.loading / data / error` | `status: PageStatus.loading / success / failure` enum in state |
| Notifier `state = state.copyWith(...)` | `emit(state.copyWith(...))` |
| `autoDispose` | Default — BLoC is closed when its `BlocProvider` leaves the tree |
| `keepAlive` / global providers | `getIt.registerLazySingleton` + `BlocProvider.value` |

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Events | `On` prefix + action noun | `OnLoginSubmitEvent`, `OnMobileChangedEvent` |
| States | Feature + `State` | `LoginState`, `PosState` |
| BLoCs | Feature + `Bloc` | `LoginBloc`, `PosBloc` |
| Repository (abstract) | Feature + `Repository` | `LoginRepository` |
| Repository (impl) | Feature + `RepoImpl` | `LoginRepoImpl` |
| Use cases | Feature + `UseCase` | `LoginUseCase` |
| Status enums | Descriptive + `Status` | `PageStatus`, `PosSubmitStatus` |
| Handler methods | `_on` + event name (no `Event` suffix) | `_onLoginSubmit`, `_onMobileChanged` |

---

## Checklist — Adding a New Feature

```
lib/features/my_feature/
├── data/
│   ├── models/
│   │   ├── my_request.dart         # toJson()
│   │   └── my_response.dart        # fromJson()
│   └── repository_impl/
│       └── my_repo_impl.dart       # extends MyRepository, uses RequestHandler
├── domain/
│   ├── repository/
│   │   └── my_repository.dart      # abstract class, Either<String,T> returns
│   └── usecase/
│       └── my_usecase.dart         # delegates to repository
└── presentation/
    ├── bloc/
    │   ├── my_bloc.dart            # part 'my_event.dart'; part 'my_state.dart';
    │   ├── my_event.dart           # part of 'my_bloc.dart';
    │   └── my_state.dart           # part of 'my_bloc.dart';
    ├── my_screen.dart
    └── widgets/
```

Then:
1. `dependencies_provider.dart` — register `MyRepository → MyRepoImpl`, then `MyUseCase`
2. `feature_bloc_providers.dart` — add `static Widget myFeature({required Widget child})`
3. `app_router.dart` — wrap route with `FeatureBlocProviders.myFeature(child: const MyScreen())`

---

## AI Prompt — Paste This at the Top of Any Chat

```
This project uses Flutter with flutter_bloc, get_it, equatable, and fpdart.
Clean Architecture with three layers per feature: data → domain → presentation.

Rules:
- Every feature has one BLoC with part-file Events and State
- Repositories are abstract interfaces; impls live in data/repository_impl/
- Repository methods return Either<String?, T> — left is an error string, right is success
- Use cases are thin delegators that group repository methods; they never emit or call BLoCs
- get_it holds infrastructure, repositories, use cases, and app-wide singleton BLoCs
- Feature BLoCs are created per-route inside FeatureBlocProviders static factory methods,
  never registered in get_it
- App-wide BLoCs (AuthBloc, OfflineStatusBloc) are in get_it and provided via BlocProvider.value
- BlocBuilder always has buildWhen
- BlocListener is for side effects only (navigation, snackbars, dialogs)
- context.read is used inside callbacks, never inside build()
- context.select is used for single-field subscriptions in leaf widgets
- State uses copyWith with clearX = false bool flags for nullable fields
- State always has a factory State.initial()
- BLoC handlers always check emit.isDone after every await
- BLoC handlers use Either.fold, never isLeft()/isRight() checks
- Timers and subscriptions are stored as BLoC fields and cancelled in close()
- Never call getIt inside BLoC handlers — inject in the constructor

Do not use: ref, Provider, StateNotifier, ChangeNotifier, context.watch, or InheritedWidget.
```
