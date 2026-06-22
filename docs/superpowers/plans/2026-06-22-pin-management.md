# PIN Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the owner set a required PIN when creating a cashier (and change/disable it later, persisted to the backend), and let the logged-in user change or disable their own PIN locally from Settings.

**Architecture:** Cashier PINs are a backend credential — threaded through the `UserBloc`/`UsersUseCase`/repo as a `pin` field on create plus `setCashierPin`/`disableCashierPin` calls; the app does NOT write a local vault record for cashiers (token-sync to make cashier unlock work is the owner's deferred task). The logged-in user's own PIN lives in the local `PinVaultService` vault; change/disable mutate it directly, reusing the existing `PinBloc` + PIN UI primitives.

**Tech Stack:** Flutter, flutter_bloc, get_it, fpdart (`Either`), the existing `PinVaultService`/`PinBloc`/`PinScaffold`/`PinDots`/`PinKeypad`, bloc_test + mocktail.

## Global Constraints

- Cashier PIN at creation: **required**, exactly **4 digits**.
- Cashier PIN persistence: **backend** via `UserBloc`/usecase/repo. No local vault write for cashiers.
- Self PIN management: **local vault** only (`PinVaultService`).
- New PIN-related copy uses **literal English strings** (matching the existing PIN screens), NOT `context.tr` — avoids `.arb` edits.
- Cashier change/disable are owner-only (the users feature is already owner-gated).
- Cashier unlock token-sync is **out of scope** (owner's deferred follow-up).
- Reuse `PinDots`, `PinKeypad`, `PinScaffold`, `PinBloc` — no new visual language for full-screen flows.
- Backend endpoints assumed (owner will align): `POST api/v1/users/` accepts `pin`; `PATCH api/v1/users/<id>/` accepts `{"pin": "<4 digits>"}` to set/change and `{"pin": null}` to disable.

---

### Task 1: Cashier-PIN data + bloc layer (Part A backend wiring)

**Files:**
- Modify: `lib/features/users/data/models/requests/add_user_request_dto.dart`
- Modify: `lib/features/users/domain/repositories/users_repository.dart`
- Modify: `lib/features/users/data/repository_impl/users_repo_impl.dart`
- Modify: `lib/features/users/domain/usecases/users_usecase.dart`
- Modify: `lib/features/users/presentation/bloc/users_event.dart`
- Modify: `lib/features/users/presentation/bloc/users_bloc.dart`
- Test: `test/features/users/users_bloc_pin_test.dart`

**Interfaces:**
- Produces:
  - `UsersRepository.addUser({required String phone, required String fullName, required String role, required String pin})`
  - `UsersRepository.setCashierPin({required String userId, required String pin})` → `Future<Either<String?, bool>>`
  - `UsersRepository.disableCashierPin(String userId)` → `Future<Either<String?, bool>>`
  - Same three on `UsersUseCase`.
  - `OnAddUser` gains `required String pin`.
  - `OnSetCashierPin({required String userId, required String pin})`, `OnDisableCashierPin(String userId)` events.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';

class _MockUseCase extends Mock implements UsersUseCase {}

void main() {
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.getUsers()).thenAnswer(
        (_) async => const Right(UserResponseDto(success: true, data: [])));
  });

  blocTest<UserBloc, UserState>(
    'OnAddUser forwards the pin to the use case',
    build: () {
      when(() => useCase.addUser(
            phone: any(named: 'phone'),
            fullName: any(named: 'fullName'),
            role: any(named: 'role'),
            pin: any(named: 'pin'),
          )).thenAnswer((_) async => const Right(UserData(id: 'u1')));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnAddUser(
        phone: '+249912345678', fullName: 'Cashier', role: 'cashier', pin: '1234')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => useCase.addUser(
          phone: '+249912345678',
          fullName: 'Cashier',
          role: 'cashier',
          pin: '1234',
        )).called(1),
  );

  blocTest<UserBloc, UserState>(
    'OnSetCashierPin calls setCashierPin',
    build: () {
      when(() => useCase.setCashierPin(
            userId: any(named: 'userId'),
            pin: any(named: 'pin'),
          )).thenAnswer((_) async => const Right(true));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnSetCashierPin(userId: 'u1', pin: '5678')),
    wait: const Duration(milliseconds: 50),
    verify: (_) =>
        verify(() => useCase.setCashierPin(userId: 'u1', pin: '5678')).called(1),
  );

  blocTest<UserBloc, UserState>(
    'OnDisableCashierPin calls disableCashierPin',
    build: () {
      when(() => useCase.disableCashierPin(any()))
          .thenAnswer((_) async => const Right(true));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnDisableCashierPin('u1')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => useCase.disableCashierPin('u1')).called(1),
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/users/users_bloc_pin_test.dart`
Expected: FAIL — `pin` param / new events not defined.

- [ ] **Step 3: Add `pin` to the request DTO**

In `add_user_request_dto.dart`, add the field and serialize it:

```dart
class AddUserRequestDto {
  String? fullName;
  String? address;
  String? phone;
  String? role;
  String? pin;

  AddUserRequestDto({this.fullName, this.address, this.phone, this.role, this.pin});

  AddUserRequestDto.fromJson(Map<String, dynamic> json) {
    fullName = json['full_name'];
    address = json['address'];
    phone = json['phone'];
    role = json['role'];
    pin = json['pin'];
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (pin != null) 'pin': pin,
    };
  }
}
```

- [ ] **Step 4: Extend the repository interface**

In `users_repository.dart`, update `addUser` and add two methods:

```dart
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    required String pin,
  });

  Future<Either<String?, bool>> setCashierPin({
    required String userId,
    required String pin,
  });

  Future<Either<String?, bool>> disableCashierPin(String userId);
```

- [ ] **Step 5: Implement in the repo impl**

In `users_repo_impl.dart`, update `addUser` and add the two methods:

```dart
  @override
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    required String pin,
  }) {
    return requestHandler.handlePostRequest(
      'api/v1/users/',
          (data) => UserData.fromJson(data as Map<String, dynamic>),
      data: {'phone': phone, 'full_name': fullName, 'role': role, 'pin': pin},
    );
  }

  @override
  Future<Either<String?, bool>> setCashierPin({
    required String userId,
    required String pin,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
          (_) => true,
      data: {'pin': pin},
    );
  }

  @override
  Future<Either<String?, bool>> disableCashierPin(String userId) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
          (_) => true,
      data: {'pin': null},
    );
  }
```

- [ ] **Step 6: Extend the use case**

In `users_usecase.dart`, update `addUser` and add the two methods:

```dart
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    required String pin,
  }) => repository.addUser(
      phone: phone, fullName: fullName, role: role, pin: pin);

  Future<Either<String?, bool>> setCashierPin({
    required String userId,
    required String pin,
  }) => repository.setCashierPin(userId: userId, pin: pin);

  Future<Either<String?, bool>> disableCashierPin(String userId) =>
      repository.disableCashierPin(userId);
```

- [ ] **Step 7: Add events**

In `users_event.dart`, add `pin` to `OnAddUser` and add two events:

```dart
class OnAddUser extends UserEvent {
  final String  phone;
  final String  fullName;
  final String  role;
  final String  pin;
  final String? shopId;

  const OnAddUser({
    required this.phone,
    required this.fullName,
    required this.role,
    required this.pin,
    this.shopId,
  });

  @override List<Object?> get props => [phone, fullName, role, pin, shopId];
}

class OnSetCashierPin extends UserEvent {
  final String userId;
  final String pin;
  const OnSetCashierPin({required this.userId, required this.pin});
  @override List<Object?> get props => [userId, pin];
}

class OnDisableCashierPin extends UserEvent {
  final String userId;
  const OnDisableCashierPin(this.userId);
  @override List<Object?> get props => [userId];
}
```

- [ ] **Step 8: Wire the bloc handlers**

In `users_bloc.dart`, register the events in the constructor:

```dart
    on<OnSetCashierPin>(_onSetCashierPin);
    on<OnDisableCashierPin>(_onDisableCashierPin);
```

Pass `pin` in `_onAddUser`:

```dart
    final result = await useCase.addUser(
      phone:    event.phone,
      fullName: event.fullName,
      role:     event.role,
      pin:      event.pin,
    );
```

Add the two handlers:

```dart
  Future<void> _onSetCashierPin(
      OnSetCashierPin event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.setCashierPin(
        userId: event.userId, pin: event.pin);
    result.fold(
          (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure, submitError: error)),
          (_) {
        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(OnUserInitial());
      },
    );
  }

  Future<void> _onDisableCashierPin(
      OnDisableCashierPin event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.disableCashierPin(event.userId);
    result.fold(
          (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure, submitError: error)),
          (_) {
        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(OnUserInitial());
      },
    );
  }
```

- [ ] **Step 9: Run test to verify it passes**

Run: `flutter test test/features/users/users_bloc_pin_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 10: Commit**

```bash
git add lib/features/users test/features/users/users_bloc_pin_test.dart
git commit -m "feat(pin): cashier PIN data + bloc layer (create/set/disable)"
```

---

### Task 2: Required PIN field on the Add Cashier sheet

**Files:**
- Create: `lib/features/pin/presentation/widgets/pin_digits_field.dart`
- Modify: `lib/features/users/presentation/widgets/add_user_sheet.dart`
- Test: `test/features/pin/pin_digits_field_test.dart`

**Interfaces:**
- Consumes: `OnAddUser(..., pin)` (Task 1).
- Produces: `PinDigitsField` — a 4-digit obscured numeric input.
  - `PinDigitsField({required TextEditingController controller, FocusNode? focusNode, String? errorText})`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_digits_field.dart';
import 'package:amana_pos/theme/app_theme.dart';

void main() {
  testWidgets('accepts only 4 digits', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: PinDigitsField(controller: controller)),
    ));
    await tester.enterText(find.byType(TextField), '12345678');
    expect(controller.text.length, 4);
    expect(controller.text, '1234');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_digits_field_test.dart`
Expected: FAIL — `PinDigitsField` not defined.

- [ ] **Step 3: Implement `PinDigitsField`**

```dart
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';

/// A compact 4-digit obscured PIN input for form sheets (distinct from the
/// full-screen keypad). Digits only, max length 4.
class PinDigitsField extends StatelessWidget {
  const PinDigitsField({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? colors.danger : colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: AppTextStyles.bs400(context, color: colors.textPrimary)
                  .copyWith(letterSpacing: 8, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '••••',
                prefixIcon: Icon(SolarIconsOutline.lockKeyhole,
                    size: 18, color: colors.textHint),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 22,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(errorText!,
                      style: AppTextStyles.sm200(context, color: colors.danger)),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_digits_field_test.dart`
Expected: PASS.

- [ ] **Step 5: Add the PIN field to the add-cashier sheet**

In `add_user_sheet.dart`:

Add the import:

```dart
import 'package:amana_pos/features/pin/presentation/widgets/pin_digits_field.dart';
```

Add a controller + error field in `_AddUserSheetState` (near `_nameCtrl`):

```dart
  late final TextEditingController _pinCtrl;
  String? _pinError;
```

Initialize/dispose it alongside the others (`_pinCtrl = TextEditingController();` in `initState`, `_pinCtrl.dispose();` in `dispose`).

In `_submit()`, after the phone validation block and before dispatching, validate the PIN:

```dart
    if (_pinCtrl.text.trim().length != 4) {
      setState(() => _pinError = 'Enter a 4-digit PIN.');
      return;
    }
```

Pass it in the dispatched event:

```dart
    context.read<UserBloc>().add(
      OnAddUser(
        phone: _fullPhone,
        fullName: _nameCtrl.text.trim(),
        role: _selectedRole,
        pin: _pinCtrl.text.trim(),
        shopId: _selectedShopId,
      ),
    );
```

Add the field UI to the form `Column` (just after the Role section's `RoleHint`, before the shop pickers):

```dart
              const SizedBox(height: AppDims.s4),
              const FieldLabel(label: 'PIN', required: true),
              const SizedBox(height: AppDims.s1),
              PinDigitsField(
                controller: _pinCtrl,
                errorText: _pinError,
              ),
```

Clear the error on change by wrapping — set `_pinError = null` inside a listener; simplest is to clear it in `_submit` retries, but to clear live, add in `initState`:

```dart
    _pinCtrl.addListener(() {
      if (_pinError != null) setState(() => _pinError = null);
    });
```

- [ ] **Step 6: Verify analyze**

Run: `flutter analyze lib/features/users/presentation/widgets/add_user_sheet.dart lib/features/pin/presentation/widgets/pin_digits_field.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/pin/presentation/widgets/pin_digits_field.dart lib/features/users/presentation/widgets/add_user_sheet.dart test/features/pin/pin_digits_field_test.dart
git commit -m "feat(pin): required PIN field on add-cashier sheet"
```

---

### Task 3: Owner change/disable a cashier's PIN

**Files:**
- Create: `lib/features/users/presentation/widgets/cashier_pin_sheet.dart`
- Modify: `lib/features/users/presentation/user_detail_screen.dart`

**Interfaces:**
- Consumes: `OnSetCashierPin`, `OnDisableCashierPin` (Task 1), `PinDigitsField` (Task 2), `UserData` (has `id`).
- Produces: `void showCashierPinSheet(BuildContext context, {required String userId})` — enter + confirm new PIN, dispatches `OnSetCashierPin`.

- [ ] **Step 1: Implement the change-PIN sheet**

Create `cashier_pin_sheet.dart`. It reuses the adaptive panel pattern from `add_user_sheet.dart` and `PinDigitsField`. Provide the existing `UserBloc` to the sheet:

```dart
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_digits_field.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_sheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showCashierPinSheet(BuildContext context, {required String userId}) {
  final userBloc = context.read<UserBloc>();
  showAdaptivePanel(
    context,
    desktopWidth: 420,
    builder: (_) => BlocProvider.value(
      value: userBloc,
      child: _CashierPinSheet(userId: userId),
    ),
  );
}

class _CashierPinSheet extends StatefulWidget {
  const _CashierPinSheet({required this.userId});
  final String userId;

  @override
  State<_CashierPinSheet> createState() => _CashierPinSheetState();
}

class _CashierPinSheetState extends State<_CashierPinSheet> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinCtrl.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Enter a 4-digit PIN.');
      return;
    }
    if (pin != _confirmCtrl.text.trim()) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    context.read<UserBloc>().add(OnSetCashierPin(userId: widget.userId, pin: pin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'PIN updated.', isInfo: true);
        } else if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong.',
            isError: true,
          );
        }
      },
      child: ProductSheetShell(
        title: 'Set cashier PIN',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel(label: 'New PIN', required: true),
            const SizedBox(height: AppDims.s1),
            PinDigitsField(controller: _pinCtrl, errorText: _error),
            const SizedBox(height: AppDims.s2),
            const FieldLabel(label: 'Confirm PIN', required: true),
            const SizedBox(height: AppDims.s1),
            PinDigitsField(controller: _confirmCtrl),
            const SizedBox(height: AppDims.s4),
            BlocSelector<UserBloc, UserState, UserSubmitStatus>(
              selector: (s) => s.submitStatus,
              builder: (context, status) => UserSubmitButton(
                label: 'Save PIN',
                onPressed: status == UserSubmitStatus.loading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add change/disable entry points in the cashier detail screen**

In `user_detail_screen.dart`, import the sheet and `OnDisableCashierPin`:

```dart
import 'package:amana_pos/features/users/presentation/widgets/cashier_pin_sheet.dart';
```

Add two actions to the detail UI (place them with the other per-cashier actions; use the screen's existing action/row style). "Change PIN" calls:

```dart
showCashierPinSheet(context, userId: user.id ?? '');
```

"Disable PIN" shows a confirm dialog, then on confirm:

```dart
context.read<UserBloc>().add(OnDisableCashierPin(user.id ?? ''));
```

Use the existing confirm-dialog pattern in the users feature (mirror `deactivate_user_sheet.dart`). Guard both behind a non-empty `user.id`.

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/users/presentation/widgets/cashier_pin_sheet.dart lib/features/users/presentation/user_detail_screen.dart`
Expected: No errors.

- [ ] **Step 4: Manual smoke (documented)**

As owner, open a cashier → Change PIN → enter+confirm → expect "PIN updated". Disable PIN → confirm → expect success snackbar.

- [ ] **Step 5: Commit**

```bash
git add lib/features/users/presentation/widgets/cashier_pin_sheet.dart lib/features/users/presentation/user_detail_screen.dart
git commit -m "feat(pin): owner can change/disable a cashier PIN"
```

---

### Task 4: `PinVaultService.changePin`

**Files:**
- Modify: `lib/features/pin/data/pin_vault_service.dart`
- Test: `test/features/pin/pin_vault_change_pin_test.dart`

**Interfaces:**
- Produces:
  - `enum ChangePinResult { success, pinTaken, userNotFound }`
  - `Future<ChangePinResult> PinVaultService.changePin(String userId, String newPin)`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';

class _FakeCache extends Mock implements CacheStorage {}

void main() {
  late _FakeCache cache;
  late PinVaultService service;
  Map<String, Object?> store = {};

  PinUserRecord rec(String userId, String pin) {
    final salt = PinHasher.generateSalt();
    return PinUserRecord(
      userId: userId, businessId: 'b1', tenantId: 'b1',
      fullName: 'U', role: 'cashier', phone: '+1',
      pinSalt: salt, pinHash: PinHasher.hashPin(pin, salt),
      accessToken: 'acc', refreshToken: 'ref',
      profileJson: {'id': userId}, enrolledAt: 'n', lastUnlockAt: 'n',
    );
  }

  setUp(() {
    cache = _FakeCache();
    store = {};
    when(() => cache.getObject('pin_vault'))
        .thenAnswer((_) async => store['pin_vault']);
    when(() => cache.saveObject('pin_vault', any())).thenAnswer((inv) async {
      store['pin_vault'] = inv.positionalArguments[1];
      return true;
    });
    service = PinVaultService(cache);
  });

  test('changePin updates the hash and keeps tokens', () async {
    await service.enrollUser(rec('u1', '1111'));
    final result = await service.changePin('u1', '2222');
    expect(result, ChangePinResult.success);
    expect((await service.findUserByPin('2222'))?.userId, 'u1');
    expect(await service.findUserByPin('1111'), isNull);
  });

  test('changePin to a PIN used by another user is rejected', () async {
    await service.enrollUser(rec('u1', '1111'));
    await service.enrollUser(rec('u2', '2222'));
    expect(await service.changePin('u1', '2222'), ChangePinResult.pinTaken);
  });

  test('changePin for unknown user returns userNotFound', () async {
    expect(await service.changePin('ghost', '0000'), ChangePinResult.userNotFound);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_vault_change_pin_test.dart`
Expected: FAIL — `changePin` / `ChangePinResult` not defined.

- [ ] **Step 3: Implement `changePin`**

In `pin_vault_service.dart`, add the enum at the top (after imports):

```dart
enum ChangePinResult { success, pinTaken, userNotFound }
```

Add the method to the class:

```dart
  Future<ChangePinResult> changePin(String userId, String newPin) async {
    final vault = await _read();
    final users = _users(vault);
    final index = users.indexWhere((u) => u.userId == userId);
    if (index < 0) return ChangePinResult.userNotFound;

    // Reject if a DIFFERENT user already uses this PIN.
    for (var i = 0; i < users.length; i++) {
      if (i == index) continue;
      if (PinHasher.hashPin(newPin, users[i].pinSalt) == users[i].pinHash) {
        return ChangePinResult.pinTaken;
      }
    }

    final old = users[index];
    final salt = PinHasher.generateSalt();
    users[index] = PinUserRecord(
      userId: old.userId,
      businessId: old.businessId,
      tenantId: old.tenantId,
      fullName: old.fullName,
      role: old.role,
      phone: old.phone,
      pinSalt: salt,
      pinHash: PinHasher.hashPin(newPin, salt),
      accessToken: old.accessToken,
      refreshToken: old.refreshToken,
      profileJson: old.profileJson,
      enrolledAt: old.enrolledAt,
      lastUnlockAt: old.lastUnlockAt,
    );
    vault['users'] = users.map((e) => e.toJson()).toList();
    await _write(vault);
    return ChangePinResult.success;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_vault_change_pin_test.dart`
Expected: PASS (3).

- [ ] **Step 5: Commit**

```bash
git add lib/features/pin/data/pin_vault_service.dart test/features/pin/pin_vault_change_pin_test.dart
git commit -m "feat(pin): PinVaultService.changePin"
```

---

### Task 5: `PinBloc` change mode

**Files:**
- Modify: `lib/features/pin/presentation/bloc/pin_state.dart`
- Modify: `lib/features/pin/presentation/bloc/pin_bloc.dart`
- Test: `test/features/pin/pin_bloc_change_test.dart`

**Interfaces:**
- Consumes: `PinVaultService.changePin` + `ChangePinResult` (Task 4).
- Produces:
  - `PinMode.change` enum value.
  - `PinState.currentVerified` (bool, default false).
  - `PinBloc({..., this.changeUserId})` — `String? changeUserId` used in change mode.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';

class _MockVault extends Mock implements PinVaultService {}
class _MockCache extends Mock implements CacheStorage {}
class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockVault vault;
  late _MockCache cache;
  late _MockAuthBloc authBloc;

  PinUserRecord rec() => const PinUserRecord(
        userId: 'u1', businessId: 'b1', tenantId: 't1', fullName: 'U',
        role: 'cashier', phone: '+1', pinSalt: 's', pinHash: 'h',
        accessToken: 'acc', refreshToken: 'ref',
        profileJson: {'id': 'u1'}, enrolledAt: 'n', lastUnlockAt: 'n',
      );

  setUp(() {
    vault = _MockVault();
    cache = _MockCache();
    authBloc = _MockAuthBloc();
    when(() => vault.lockoutRemaining()).thenAnswer((_) async => Duration.zero);
  });

  void typed(PinBloc b, String pin) {
    for (final d in pin.split('')) {
      b.add(PinDigitPressed(d));
    }
  }

  blocTest<PinBloc, PinState>(
    'verify current -> new -> confirm calls changePin and reaches success',
    build: () {
      when(() => vault.findUserByPin('1111')).thenAnswer((_) async => rec());
      when(() => vault.changePin('u1', '2222'))
          .thenAnswer((_) async => ChangePinResult.success);
      return PinBloc(
        vault: vault, cache: cache, authBloc: authBloc,
        mode: PinMode.change, changeUserId: 'u1',
      );
    },
    act: (b) async {
      typed(b, '1111');
      await Future.delayed(const Duration(milliseconds: 20));
      typed(b, '2222');
      await Future.delayed(const Duration(milliseconds: 20));
      typed(b, '2222');
    },
    wait: const Duration(milliseconds: 80),
    verify: (_) => verify(() => vault.changePin('u1', '2222')).called(1),
  );

  blocTest<PinBloc, PinState>(
    'wrong current PIN does not advance',
    build: () {
      when(() => vault.findUserByPin('0000')).thenAnswer((_) async => null);
      return PinBloc(
        vault: vault, cache: cache, authBloc: authBloc,
        mode: PinMode.change, changeUserId: 'u1',
      );
    },
    act: (b) => typed(b, '0000'),
    wait: const Duration(milliseconds: 40),
    verify: (bloc) {
      expect(bloc.state.currentVerified, isFalse);
      verifyNever(() => vault.changePin(any(), any()));
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_bloc_change_test.dart`
Expected: FAIL — `PinMode.change` / `changeUserId` / `currentVerified` not defined.

- [ ] **Step 3: Extend `PinState`**

In `pin_state.dart`, add `change` to the enum and a `currentVerified` field:

```dart
enum PinMode { setup, unlock, change }
```

Add the field, constructor param, factory default, and copyWith handling:

```dart
  final bool currentVerified;
```
- In the constructor: `this.currentVerified = false,`
- In `PinState.initial`: add `currentVerified: false,`
- In `copyWith` params: `bool? currentVerified,`
- In the returned `PinState`: `currentVerified: currentVerified ?? this.currentVerified,`

- [ ] **Step 4: Extend `PinBloc`**

In `pin_bloc.dart`, add the field + constructor param:

```dart
  final String? changeUserId;
```
Add `this.changeUserId,` to the constructor parameter list.

In `_onDigit`, route change mode to a new handler. Replace the dispatch tail:

```dart
    if (entered.length == 4) {
      if (mode == PinMode.setup) {
        await _handleSetup(entered, emit);
      } else if (mode == PinMode.change) {
        await _handleChange(entered, emit);
      } else {
        await _handleUnlock(entered, emit);
      }
    }
```

Add the handler:

```dart
  Future<void> _handleChange(String pin, Emitter<PinState> emit) async {
    if (!state.currentVerified) {
      final match = await vault.findUserByPin(pin);
      if (match == null || match.userId != changeUserId) {
        emit(state.copyWith(
            phase: PinPhase.mismatch, entered: '',
            errorText: 'Incorrect PIN. Try again.'));
        return;
      }
      emit(state.copyWith(
          currentVerified: true, entered: '', phase: PinPhase.entering));
      return;
    }
    if (state.firstEntry.isEmpty) {
      emit(state.copyWith(
          firstEntry: pin, entered: '', phase: PinPhase.confirming));
      return;
    }
    if (pin != state.firstEntry) {
      emit(state.copyWith(
          phase: PinPhase.mismatch, entered: '', firstEntry: '',
          errorText: 'PINs did not match. Try again.'));
      return;
    }
    final result = await vault.changePin(changeUserId ?? '', pin);
    if (result == ChangePinResult.pinTaken) {
      emit(state.copyWith(
          phase: PinPhase.error, entered: '', firstEntry: '',
          errorText: 'This PIN is already in use. Choose another.'));
      return;
    }
    if (result == ChangePinResult.userNotFound) {
      emit(state.copyWith(phase: PinPhase.error, errorText: 'Change unavailable.'));
      return;
    }
    emit(state.copyWith(phase: PinPhase.success));
  }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_bloc_change_test.dart`
Expected: PASS (2).

- [ ] **Step 6: Commit**

```bash
git add lib/features/pin/presentation/bloc/ test/features/pin/pin_bloc_change_test.dart
git commit -m "feat(pin): PinBloc change mode (verify -> new -> confirm)"
```

---

### Task 6: Change-PIN screen + route + provider

**Files:**
- Create: `lib/features/pin/presentation/pin_change_screen.dart`
- Modify: `lib/config/router/route_strings.dart`
- Modify: `lib/config/router/app_router.dart`
- Modify: `lib/config/providers/feature_bloc_providers.dart`
- Test: `test/features/pin/pin_change_screen_test.dart`

**Interfaces:**
- Consumes: `PinBloc` change mode (Task 5), `PinScaffold`/`PinDots`/`PinKeypad`.
- Produces: `RouteStrings.pinChangeScreen`; `FeatureBlocProviders.pinChange({child, userId})`; `PinChangeScreen`.

- [ ] **Step 1: Implement the screen**

```dart
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinChangeScreen extends StatelessWidget {
  const PinChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (p, c) => p.phase != c.phase,
      listener: (context, state) {
        if (state.phase == PinPhase.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'PIN updated.', isInfo: true);
        }
      },
      builder: (context, state) {
        final hasError =
            state.phase == PinPhase.mismatch || state.phase == PinPhase.error;
        final String title;
        final String subtitle;
        if (!state.currentVerified) {
          title = 'Enter current PIN';
          subtitle = 'Confirm it\'s you before changing your PIN.';
        } else if (state.firstEntry.isEmpty) {
          title = 'New PIN';
          subtitle = 'Choose a new 4-digit PIN.';
        } else {
          title = 'Confirm new PIN';
          subtitle = 'Enter it once more to confirm.';
        }

        return PinScaffold(
          brand: const _ChangeMark(),
          title: title,
          subtitle: subtitle,
          errorText: hasError ? state.errorText : null,
          dots: PinDots(
            filledCount: state.entered.length,
            hasError: hasError,
            success: state.phase == PinPhase.success,
          ),
          keypad: PinKeypad(
            onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
            onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
          ),
          onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
          onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
        );
      },
    );
  }
}

class _ChangeMark extends StatelessWidget {
  const _ChangeMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer.withValues(alpha: 0.5),
      ),
      child: Icon(Icons.password_rounded, size: 32, color: colors.primary),
    );
  }
}
```

- [ ] **Step 2: Add the route string**

In `route_strings.dart`, add:

```dart
  static const String pinChangeScreen = 'pinChangeScreen';
```

- [ ] **Step 3: Add the provider**

In `feature_bloc_providers.dart`, add:

```dart
  static Widget pinChange({required Widget child, required String userId}) {
    return BlocProvider(
      create: (_) => PinBloc(
        vault: getIt<PinVaultService>(),
        cache: getIt<CacheStorage>(),
        authBloc: getIt<AuthBloc>(),
        mode: PinMode.change,
        changeUserId: userId,
      ),
      child: child,
    );
  }
```

- [ ] **Step 4: Add the router case**

In `app_router.dart`, add the import for `PinChangeScreen` and a case:

```dart
      case RouteStrings.pinChangeScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          FeatureBlocProviders.pinChange(
            userId: args['userId'] as String,
            child: const PinChangeScreen(),
          ),
          settings,
        );
```

- [ ] **Step 5: Smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_change_screen.dart';
import 'package:amana_pos/theme/app_theme.dart';

class _FakePinBloc extends Mock implements PinBloc {}

void main() {
  testWidgets('shows Enter current PIN first', (tester) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.change));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<PinBloc>.value(value: bloc, child: const PinChangeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('current PIN'), findsWidgets);
  });
}
```

Run: `flutter test test/features/pin/pin_change_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/pin/presentation/pin_change_screen.dart lib/config/router/route_strings.dart lib/config/router/app_router.dart lib/config/providers/feature_bloc_providers.dart test/features/pin/pin_change_screen_test.dart
git commit -m "feat(pin): change-PIN screen, route, and provider"
```

---

### Task 7: Settings — Change PIN / Disable PIN for the current user

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

**Interfaces:**
- Consumes: `RouteStrings.pinChangeScreen` (Task 6), `PinVaultService.removeUser`, `getIt<AuthBloc>().state.profile?.id`.

- [ ] **Step 1: Add the rows to the Account section**

In `settings_screen.dart`, in `_AccountSection`'s `SettingsGroupCard` children, add two rows after the Profile row. Resolve the current user id from the auth profile in scope (`profile.id`), and gate the rows on it being non-null:

```dart
            SettingsRowItem(
              leadingIcon: SolarIconsOutline.lockKeyhole,
              title: 'Change PIN',
              subtitle: 'Update your unlock PIN',
              onTap: () {
                final userId = profile?.id;
                if (userId == null || userId.isEmpty) return;
                Navigator.of(context).pushNamed(
                  RouteStrings.pinChangeScreen,
                  arguments: {'userId': userId},
                );
              },
            ),
            SettingsRowItem(
              leadingIcon: SolarIconsOutline.lockKeyholeMinimalistic,
              title: 'Disable PIN',
              subtitle: 'Remove PIN unlock on this device',
              onTap: () => _confirmDisablePin(context, profile?.id),
            ),
```

(Match the exact `SettingsRowItem` parameter names/icons already used in the file — adapt `leadingIcon`/`title`/`subtitle`/`onTap` to the real signature; check the existing Profile row in `_AccountSection`.)

- [ ] **Step 2: Add the disable-confirm helper**

Add a top-level helper (or private function) in `settings_screen.dart`:

```dart
Future<void> _confirmDisablePin(BuildContext context, String? userId) async {
  if (userId == null || userId.isEmpty) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Disable PIN?'),
      content: const Text(
          'You\'ll sign in with your phone number next time instead of a PIN.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disable')),
      ],
    ),
  );
  if (confirmed != true) return;
  await getIt<PinVaultService>().removeUser(userId);
  GlobalSnackBar.show(message: 'PIN disabled.', isInfo: true);
}
```

Add imports as needed: `RouteStrings`, `getIt`, `PinVaultService`, `GlobalSnackBar`, `solar_icons`.

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/settings/presentation/settings_screen.dart`
Expected: No errors.

- [ ] **Step 4: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: PIN/users/settings tests pass; no new analyzer errors (pre-existing `sales_history` test failures and `tool/dev` infos excepted).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(pin): Settings change/disable PIN for the current user"
```

---

## Self-Review

**Spec coverage:**
- Required cashier PIN on create → Tasks 1, 2. ✅
- Cashier PIN to backend → Task 1 (repo `pin` field + set/disable). ✅
- Owner change/disable cashier PIN → Tasks 1, 3. ✅
- Self change PIN → Tasks 4, 5, 6, 7. ✅
- Self disable PIN → Task 7 (`removeUser`). ✅
- Reuse PIN primitives / literal copy → Tasks 2, 6 (PinScaffold/Dots/Keypad; literal strings). ✅
- `PinVaultService.changePin` (success/pin-taken/not-found) → Task 4. ✅
- Owner-only gating → Task 3 (users feature already owner-gated). ✅
- Deferred unlock token-sync → out of scope (stated in Global Constraints). ✅
- Testing strategy → tests in Tasks 1, 2, 4, 5, 6 + smoke/manual 3, 7. ✅

**Placeholder scan:** No TBD/TODO. Task 3 Step 2 and Task 7 Step 1 instruct adapting to the file's existing `SettingsRowItem`/detail-action signatures rather than guessing exact params — this is a deliberate "match the local pattern" instruction, with full code for the new logic (sheet, dialog, dispatch) provided.

**Type consistency:** `addUser(..., pin)`, `setCashierPin({userId, pin})`, `disableCashierPin(userId)`, `OnSetCashierPin`, `OnDisableCashierPin`, `ChangePinResult`, `PinMode.change`, `currentVerified`, `changeUserId`, `RouteStrings.pinChangeScreen`, `FeatureBlocProviders.pinChange` are used consistently across Tasks 1–7. ✅

## Execution Notes / Ordering

Implement in order. Part A (Tasks 1–3, backend-persisted cashier PINs) and Part B (Tasks 4–7, local self-management) are independent and could be done in either order; the numbering does A first. Task 6 depends on Tasks 4–5; Task 7 depends on Task 6.
