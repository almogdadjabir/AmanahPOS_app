# PIN Setup & Unlock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let staff enter Amana POS with a local 4-digit PIN — each user logs in fully once, sets a PIN, and thereafter the app opens to a bare PIN pad that matches the typed PIN to an enrolled user and logs them in automatically, fully offline.

**Architecture:** A local encrypted "PIN vault" (in the existing `CacheStorage`) stores one record per enrolled user: a PBKDF2-hashed PIN plus that user's tokens and cached profile. Because `AppInterceptors` reads `auth_token`/`x_tenant_iD` fresh from `CacheStorage` on every request, "switching the active user" is just writing the matched user's tokens into those keys and dispatching `OnLoadProfileEvent` on the existing `AuthBloc`. A lifecycle observer locks the app on cold start and on resume after a 2-minute background.

**Tech Stack:** Flutter, flutter_bloc, get_it, sqflite (offline), flutter_secure_storage/shared_preferences via `CacheStorage`, `crypto` (new — PBKDF2-HMAC-SHA256), bloc_test + mocktail for tests.

## Global Constraints

- PIN length: exactly **4 digits**.
- Background lock timeout: **2 minutes**.
- Lockout: after **5** failed unlock attempts → **30s** lock, escalating (30s, 60s, 120s, 300s, then stays 300s).
- Biometrics: **none**.
- Unlock screen shows **no user list** — bare PIN pad (PIN = identity).
- Hashing: **PBKDF2-HMAC-SHA256**, per-user random 16-byte salt, **100000** iterations, 32-byte derived key.
- Storage goes through `getIt<CacheStorage>()` only (encrypted on mobile, SharedPreferences on desktop — accepted).
- Vault `CacheStorage` key: `pin_vault`.
- Follow existing patterns: blocs under `lib/features/<f>/presentation/bloc/`, providers added to `FeatureBlocProviders`, routes in `RouteStrings`/`AppRouter`.
- Two UI screens (Tasks 7–8) MUST be built by invoking the **frontend-design** skill; both are responsive **mobile + desktop** and follow the existing `desktop_*` widget + `LayoutBuilder` conventions.

---

### Task 1: PIN hashing utility (`PinHasher`)

**Files:**
- Modify: `pubspec.yaml` (add `crypto: ^3.0.6` under dependencies)
- Create: `lib/features/pin/data/pin_hasher.dart`
- Test: `test/features/pin/pin_hasher_test.dart`

**Interfaces:**
- Consumes: `package:crypto` (`Hmac`, `sha256`).
- Produces:
  - `class PinHasher`
  - `static String generateSalt()` → base64 of 16 random bytes
  - `static String hashPin(String pin, String saltBase64)` → base64 of 32-byte PBKDF2-HMAC-SHA256 (100000 iterations)

- [ ] **Step 1: Add dependency**

In `pubspec.yaml`, under `dependencies:` (near `collection`/`uuid`), add:

```yaml
  crypto: ^3.0.6
```

Run: `flutter pub get`
Expected: resolves without error.

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('generateSalt returns distinct non-empty base64 salts', () {
      final a = PinHasher.generateSalt();
      final b = PinHasher.generateSalt();
      expect(a.isNotEmpty, isTrue);
      expect(a == b, isFalse);
    });

    test('hashPin is deterministic for same pin + salt', () {
      final salt = PinHasher.generateSalt();
      expect(PinHasher.hashPin('1234', salt), PinHasher.hashPin('1234', salt));
    });

    test('hashPin differs for different pins on same salt', () {
      final salt = PinHasher.generateSalt();
      expect(PinHasher.hashPin('1234', salt) == PinHasher.hashPin('5678', salt),
          isFalse);
    });

    test('hashPin differs for same pin on different salts', () {
      expect(
        PinHasher.hashPin('1234', PinHasher.generateSalt()) ==
            PinHasher.hashPin('1234', PinHasher.generateSalt()),
        isFalse,
      );
    });

    test('hash decodes to 32 bytes', () {
      final salt = PinHasher.generateSalt();
      final bytes = base64Decode(PinHasher.hashPin('1234', salt));
      expect(bytes.length, 32);
    });
  });
}
```

Add `import 'dart:convert';` at top of the test.

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_hasher_test.dart`
Expected: FAIL — `pin_hasher.dart` / `PinHasher` not found.

- [ ] **Step 4: Implement `PinHasher`**

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 PIN hashing. dkLen = 32 (== SHA-256 output) so exactly
/// one PBKDF2 block is required.
class PinHasher {
  static const int _iterations = 100000;
  static const int _saltBytes = 16;
  static final Random _rng = Random.secure();

  static String generateSalt() {
    final bytes = Uint8List(_saltBytes);
    for (var i = 0; i < _saltBytes; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    return base64Encode(bytes);
  }

  static String hashPin(String pin, String saltBase64) {
    final salt = base64Decode(saltBase64);
    final hmac = Hmac(sha256, utf8.encode(pin));

    // PBKDF2 block index 1: INT(1) big-endian appended to salt.
    final block = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..[salt.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final result = Uint8List.fromList(u);

    for (var i = 1; i < _iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return base64Encode(result);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_hasher_test.dart`
Expected: PASS (all 5).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/pin/data/pin_hasher.dart test/features/pin/pin_hasher_test.dart
git commit -m "feat(pin): add PBKDF2 PIN hashing utility"
```

---

### Task 2: PIN vault record model (`PinUserRecord`)

**Files:**
- Create: `lib/features/pin/data/pin_user_record.dart`
- Test: `test/features/pin/pin_user_record_test.dart`

**Interfaces:**
- Produces:
  - `class PinUserRecord` with fields: `String userId, businessId, tenantId, fullName, role, phone, pinSalt, pinHash, accessToken, refreshToken, profileJson` (`Map<String,dynamic>`), `String enrolledAt, lastUnlockAt`.
  - `Map<String,dynamic> toJson()` / `factory PinUserRecord.fromJson(Map<String,dynamic>)`
  - `PinUserRecord copyWith({String? lastUnlockAt})`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';

void main() {
  PinUserRecord sample() => PinUserRecord(
        userId: 'u1', businessId: 'b1', tenantId: 't1',
        fullName: 'Cashier One', role: 'cashier', phone: '+249...',
        pinSalt: 'salt', pinHash: 'hash',
        accessToken: 'acc', refreshToken: 'ref',
        profileJson: const {'id': 'u1', 'role': 'cashier'},
        enrolledAt: '2026-06-22T00:00:00Z',
        lastUnlockAt: '2026-06-22T00:00:00Z',
      );

  test('round-trips through json', () {
    final r = sample();
    final back = PinUserRecord.fromJson(r.toJson());
    expect(back.userId, 'u1');
    expect(back.pinHash, 'hash');
    expect(back.profileJson['role'], 'cashier');
    expect(back.accessToken, 'acc');
  });

  test('copyWith updates lastUnlockAt only', () {
    final r = sample().copyWith(lastUnlockAt: '2026-06-23T00:00:00Z');
    expect(r.lastUnlockAt, '2026-06-23T00:00:00Z');
    expect(r.userId, 'u1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_user_record_test.dart`
Expected: FAIL — type not found.

- [ ] **Step 3: Implement `PinUserRecord`**

```dart
class PinUserRecord {
  final String userId;
  final String businessId;
  final String tenantId;
  final String fullName;
  final String role;
  final String phone;
  final String pinSalt;
  final String pinHash;
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> profileJson;
  final String enrolledAt;
  final String lastUnlockAt;

  const PinUserRecord({
    required this.userId,
    required this.businessId,
    required this.tenantId,
    required this.fullName,
    required this.role,
    required this.phone,
    required this.pinSalt,
    required this.pinHash,
    required this.accessToken,
    required this.refreshToken,
    required this.profileJson,
    required this.enrolledAt,
    required this.lastUnlockAt,
  });

  PinUserRecord copyWith({String? lastUnlockAt}) => PinUserRecord(
        userId: userId,
        businessId: businessId,
        tenantId: tenantId,
        fullName: fullName,
        role: role,
        phone: phone,
        pinSalt: pinSalt,
        pinHash: pinHash,
        accessToken: accessToken,
        refreshToken: refreshToken,
        profileJson: profileJson,
        enrolledAt: enrolledAt,
        lastUnlockAt: lastUnlockAt ?? this.lastUnlockAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'businessId': businessId,
        'tenantId': tenantId,
        'fullName': fullName,
        'role': role,
        'phone': phone,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'profileJson': profileJson,
        'enrolledAt': enrolledAt,
        'lastUnlockAt': lastUnlockAt,
      };

  factory PinUserRecord.fromJson(Map<String, dynamic> json) => PinUserRecord(
        userId: json['userId'] as String? ?? '',
        businessId: json['businessId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        pinSalt: json['pinSalt'] as String? ?? '',
        pinHash: json['pinHash'] as String? ?? '',
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        profileJson:
            (json['profileJson'] as Map?)?.cast<String, dynamic>() ?? const {},
        enrolledAt: json['enrolledAt'] as String? ?? '',
        lastUnlockAt: json['lastUnlockAt'] as String? ?? '',
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_user_record_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pin/data/pin_user_record.dart test/features/pin/pin_user_record_test.dart
git commit -m "feat(pin): add PinUserRecord model"
```

---

### Task 3: PIN vault service (`PinVaultService`)

**Files:**
- Create: `lib/features/pin/data/pin_vault_service.dart`
- Test: `test/features/pin/pin_vault_service_test.dart`

**Interfaces:**
- Consumes: `CacheStorage` (`getObject(String)`, `saveObject(String, Object?)`), `PinHasher`, `PinUserRecord`.
- Produces `class PinVaultService` constructed as `PinVaultService(this._cache)` with:
  - `Future<bool> hasAnyEnrolled()`
  - `Future<bool> isUserEnrolled(String userId)`
  - `Future<bool> isPinTaken(String pin)`
  - `Future<void> enrollUser(PinUserRecord record)`
  - `Future<PinUserRecord?> findUserByPin(String pin)` — returns match or null; also updates `lastUnlockAt` + clears attempts on match.
  - `Future<void> recordFailedAttempt()`
  - `Future<void> clearAttempts()`
  - `Future<Duration> lockoutRemaining()` — `Duration.zero` if not locked.
  - `Future<void> removeUser(String userId)`
  - `Future<void> clearVault()`
- Vault JSON: `{ "version": 1, "lockedUntil": String?, "failedAttempts": int, "users": [PinUserRecord...] }` under key `pin_vault`.
- Lockout policy: attempts counted globally; on reaching a 5/10/15/... multiple of 5, set `lockedUntil = now + escalating`, where escalating index = `(failedAttempts ~/ 5) - 1` into `[30,60,120,300]` clamped to last.

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

  PinUserRecord record(String userId, String pin, {String business = 'b1'}) {
    final salt = PinHasher.generateSalt();
    return PinUserRecord(
      userId: userId, businessId: business, tenantId: business,
      fullName: 'User $userId', role: 'cashier', phone: '+1',
      pinSalt: salt, pinHash: PinHasher.hashPin(pin, salt),
      accessToken: 'acc-$userId', refreshToken: 'ref-$userId',
      profileJson: {'id': userId}, enrolledAt: 'now', lastUnlockAt: 'now',
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

  test('empty vault has no enrolled users', () async {
    expect(await service.hasAnyEnrolled(), isFalse);
  });

  test('enroll then find by correct pin returns the user', () async {
    await service.enrollUser(record('u1', '1234'));
    expect(await service.hasAnyEnrolled(), isTrue);
    final found = await service.findUserByPin('1234');
    expect(found?.userId, 'u1');
  });

  test('find by wrong pin returns null', () async {
    await service.enrollUser(record('u1', '1234'));
    expect(await service.findUserByPin('9999'), isNull);
  });

  test('two users, each pin resolves to the right user', () async {
    await service.enrollUser(record('u1', '1111'));
    await service.enrollUser(record('u2', '2222'));
    expect((await service.findUserByPin('1111'))?.userId, 'u1');
    expect((await service.findUserByPin('2222'))?.userId, 'u2');
  });

  test('isPinTaken true for an existing pin', () async {
    await service.enrollUser(record('u1', '1234'));
    expect(await service.isPinTaken('1234'), isTrue);
    expect(await service.isPinTaken('0000'), isFalse);
  });

  test('re-enrolling same userId replaces, not duplicates', () async {
    await service.enrollUser(record('u1', '1111'));
    await service.enrollUser(record('u1', '2222'));
    expect((await service.findUserByPin('1111')), isNull);
    expect((await service.findUserByPin('2222'))?.userId, 'u1');
  });

  test('5 failed attempts triggers 30s lockout', () async {
    for (var i = 0; i < 5; i++) {
      await service.recordFailedAttempt();
    }
    final remaining = await service.lockoutRemaining();
    expect(remaining.inSeconds, greaterThan(25));
    expect(remaining.inSeconds, lessThanOrEqualTo(30));
  });

  test('clearAttempts removes lockout', () async {
    for (var i = 0; i < 5; i++) {
      await service.recordFailedAttempt();
    }
    await service.clearAttempts();
    expect((await service.lockoutRemaining()), Duration.zero);
  });

  test('removeUser drops the record', () async {
    await service.enrollUser(record('u1', '1234'));
    await service.removeUser('u1');
    expect(await service.hasAnyEnrolled(), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_vault_service_test.dart`
Expected: FAIL — `PinVaultService` not found.

- [ ] **Step 3: Implement `PinVaultService`**

```dart
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';

class PinVaultService {
  PinVaultService(this._cache);

  final CacheStorage _cache;
  static const _key = 'pin_vault';
  static const _escalation = [30, 60, 120, 300];

  Future<Map<String, dynamic>> _read() async {
    final raw = await _cache.getObject(_key);
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'version': 1, 'lockedUntil': null, 'failedAttempts': 0, 'users': []};
  }

  Future<void> _write(Map<String, dynamic> vault) async {
    await _cache.saveObject(_key, vault);
  }

  List<PinUserRecord> _users(Map<String, dynamic> vault) =>
      ((vault['users'] as List?) ?? const [])
          .map((e) => PinUserRecord.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  Future<bool> hasAnyEnrolled() async => _users(await _read()).isNotEmpty;

  Future<bool> isUserEnrolled(String userId) async =>
      _users(await _read()).any((u) => u.userId == userId);

  Future<bool> isPinTaken(String pin) async {
    for (final u in _users(await _read())) {
      if (PinHasher.hashPin(pin, u.pinSalt) == u.pinHash) return true;
    }
    return false;
  }

  Future<void> enrollUser(PinUserRecord record) async {
    final vault = await _read();
    final users = _users(vault)..removeWhere((u) => u.userId == record.userId);
    users.add(record);
    vault['users'] = users.map((u) => u.toJson()).toList();
    await _write(vault);
  }

  Future<PinUserRecord?> findUserByPin(String pin) async {
    final vault = await _read();
    final users = _users(vault);
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      if (PinHasher.hashPin(pin, u.pinSalt) == u.pinHash) {
        final updated = u.copyWith(lastUnlockAt: DateTime.now().toIso8601String());
        users[i] = updated;
        vault['users'] = users.map((e) => e.toJson()).toList();
        vault['failedAttempts'] = 0;
        vault['lockedUntil'] = null;
        await _write(vault);
        return updated;
      }
    }
    return null;
  }

  Future<void> recordFailedAttempt() async {
    final vault = await _read();
    final attempts = ((vault['failedAttempts'] as int?) ?? 0) + 1;
    vault['failedAttempts'] = attempts;
    if (attempts % 5 == 0) {
      final idx = (attempts ~/ 5) - 1;
      final secs = _escalation[idx.clamp(0, _escalation.length - 1)];
      vault['lockedUntil'] =
          DateTime.now().add(Duration(seconds: secs)).toIso8601String();
    }
    await _write(vault);
  }

  Future<void> clearAttempts() async {
    final vault = await _read();
    vault['failedAttempts'] = 0;
    vault['lockedUntil'] = null;
    await _write(vault);
  }

  Future<Duration> lockoutRemaining() async {
    final vault = await _read();
    final iso = vault['lockedUntil'] as String?;
    if (iso == null) return Duration.zero;
    final until = DateTime.tryParse(iso);
    if (until == null) return Duration.zero;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> removeUser(String userId) async {
    final vault = await _read();
    final users = _users(vault)..removeWhere((u) => u.userId == userId);
    vault['users'] = users.map((u) => u.toJson()).toList();
    await _write(vault);
  }

  Future<void> clearVault() async {
    await _cache.saveObject(_key, null);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_vault_service_test.dart`
Expected: PASS (all).

- [ ] **Step 5: Commit**

```bash
git add lib/features/pin/data/pin_vault_service.dart test/features/pin/pin_vault_service_test.dart
git commit -m "feat(pin): add PinVaultService (enroll, match, lockout)"
```

---

### Task 4: DI registration + routes + bloc provider wiring

**Files:**
- Modify: `lib/utilities/dependencies_provider.dart` (register `PinVaultService` after `CacheStorage` at line ~82)
- Modify: `lib/config/router/route_strings.dart`
- Modify: `lib/config/router/app_router.dart`
- Modify: `lib/config/providers/feature_bloc_providers.dart`

**Interfaces:**
- Consumes: `PinVaultService` (Task 3), `PinBloc` (Task 6 — forward reference; this task only wires the provider method shell that Task 6 completes). To avoid a broken build, this task registers DI + routes and adds `FeatureBlocProviders.pin` returning the screens **after** Task 6 defines `PinBloc`. **Order note:** implement Task 5 (PinBloc) before the `FeatureBlocProviders.pin` part; do the DI + route-string parts here, and the provider/route-case parts land together with Task 7/8 wiring. For a clean commit, this task does only: (a) register `PinVaultService`, (b) add the two route string constants.
- Produces: `RouteStrings.pinSetupScreen`, `RouteStrings.pinUnlockScreen`; `getIt<PinVaultService>()`.

- [ ] **Step 1: Register `PinVaultService` in DI**

In `lib/utilities/dependencies_provider.dart`, immediately after the `CacheStorage` registration (line ~82), add:

```dart
    getIt.registerLazySingleton<PinVaultService>(
      () => PinVaultService(getIt<CacheStorage>()),
    );
```

Add the import at the top:

```dart
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
```

- [ ] **Step 2: Add route strings**

In `lib/config/router/route_strings.dart`, before the closing brace add:

```dart
  static const String pinSetupScreen = 'pinSetupScreen';
  static const String pinUnlockScreen = 'pinUnlockScreen';
```

- [ ] **Step 3: Verify build still compiles**

Run: `flutter analyze lib/utilities/dependencies_provider.dart lib/config/router/route_strings.dart`
Expected: No errors (unused-import warning on `PinVaultService` is acceptable until used; it is used in Step 1).

- [ ] **Step 4: Commit**

```bash
git add lib/utilities/dependencies_provider.dart lib/config/router/route_strings.dart
git commit -m "chore(pin): register PinVaultService and add PIN routes"
```

---

### Task 5: `PinBloc` (setup + unlock logic)

**Files:**
- Create: `lib/features/pin/presentation/bloc/pin_bloc.dart`
- Create: `lib/features/pin/presentation/bloc/pin_event.dart`
- Create: `lib/features/pin/presentation/bloc/pin_state.dart`
- Test: `test/features/pin/pin_bloc_test.dart`

**Interfaces:**
- Consumes: `PinVaultService`, `CacheStorage`, `AuthBloc` (`OnLoadProfileEvent`), `User` (`lib/features/login/data/models/otp_verify_response.dart`), `Constants` (`authToken`, `refreshToken`, `xTenantID`).
- Produces:
  - `enum PinMode { setup, unlock }`
  - `enum PinPhase { entering, confirming, success, mismatch, error, locked }`
  - `class PinBloc extends Bloc<PinEvent, PinState>` constructed `PinBloc({required this.vault, required this.cache, required this.authBloc, required this.mode, this.enrollUser, this.enrollTokens})`
    - `enrollUser`: `User?` (the freshly-logged-in user for setup mode)
    - `enrollTokens`: `({String access, String refresh, String tenantId})?`
  - Events: `PinDigitPressed(String d)`, `PinBackspace()`, `PinCleared()`, `PinLockoutTicked()`
  - State `PinState`: `String entered`, `String firstEntry` (setup confirm step), `PinMode mode`, `PinPhase phase`, `Duration lockoutRemaining`, `String? errorText`, `PinUserRecord? unlockedUser`.
  - On unlock success the bloc has already written tokens to `CacheStorage` and dispatched `OnLoadProfileEvent` on `authBloc`; the screen listens for `phase == success` to navigate.

**Behavior:**
- Digits append until length 4.
- **setup**: at 4 digits in `entering` → store as `firstEntry`, clear `entered`, phase `confirming`. At 4 digits in `confirming` → if equals `firstEntry` and `!vault.isPinTaken(pin)` → enroll (build `PinUserRecord` from `enrollUser`/`enrollTokens`), phase `success`. If mismatch → phase `mismatch`, reset to `entering`, clear both. If pin taken → phase `error` with `errorText = 'Choose a different PIN'`.
- **unlock**: on construction, check `vault.lockoutRemaining()`; if > 0 → phase `locked`. At 4 digits → if locked, ignore. Else `vault.findUserByPin`: match → write tokens, `authBloc.add(OnLoadProfileEvent(user: matched.profile))`, phase `success`, set `unlockedUser`. No match → `vault.recordFailedAttempt()`, re-check lockout; phase `mismatch` or `locked`, clear `entered`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
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

  setUpAll(() => registerFallbackValue(OnLoadProfileEvent()));

  setUp(() {
    vault = _MockVault();
    cache = _MockCache();
    authBloc = _MockAuthBloc();
    when(() => cache.save(any(), any())).thenAnswer((_) async => true);
    when(() => vault.lockoutRemaining()).thenAnswer((_) async => Duration.zero);
    when(() => vault.recordFailedAttempt()).thenAnswer((_) async {});
    when(() => authBloc.add(any())).thenReturn(null);
  });

  PinUserRecord rec() => const PinUserRecord(
        userId: 'u1', businessId: 'b1', tenantId: 't1', fullName: 'U',
        role: 'cashier', phone: '+1', pinSalt: 's', pinHash: 'h',
        accessToken: 'acc', refreshToken: 'ref',
        profileJson: {'id': 'u1'}, enrolledAt: 'n', lastUnlockAt: 'n',
      );

  void typed(PinBloc b, String pin) {
    for (final d in pin.split('')) {
      b.add(PinDigitPressed(d));
    }
  }

  group('unlock', () {
    blocTest<PinBloc, PinState>(
      'matching pin writes tokens, loads profile, reaches success',
      build: () {
        when(() => vault.findUserByPin('1234')).thenAnswer((_) async => rec());
        return PinBloc(
            vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.unlock);
      },
      act: (b) => typed(b, '1234'),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => cache.save(Constants.authToken, 'acc')).called(1);
        verify(() => cache.save(Constants.refreshToken, 'ref')).called(1);
        verify(() => cache.save(Constants.xTenantID, 't1')).called(1);
        verify(() => authBloc.add(any(that: isA<OnLoadProfileEvent>()))).called(1);
      },
    );

    blocTest<PinBloc, PinState>(
      'wrong pin records failed attempt and does not load profile',
      build: () {
        when(() => vault.findUserByPin('0000')).thenAnswer((_) async => null);
        return PinBloc(
            vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.unlock);
      },
      act: (b) => typed(b, '0000'),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => vault.recordFailedAttempt()).called(1);
        verifyNever(() => authBloc.add(any()));
      },
    );
  });

  group('setup', () {
    blocTest<PinBloc, PinState>(
      'enter then matching confirm enrolls and reaches success',
      build: () {
        when(() => vault.isPinTaken('1234')).thenAnswer((_) async => false);
        when(() => vault.enrollUser(any())).thenAnswer((_) async {});
        return PinBloc(
          vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.setup,
          enrollUser: const User(id: 'u1', businessId: 'b1', role: 'cashier',
              fullName: 'U', phone: '+1'),
          enrollTokens: (access: 'acc', refresh: 'ref', tenantId: 't1'),
        );
      },
      act: (b) async {
        typed(b, '1234');
        await Future.delayed(const Duration(milliseconds: 20));
        typed(b, '1234');
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) => verify(() => vault.enrollUser(any())).called(1),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pin/pin_bloc_test.dart`
Expected: FAIL — `PinBloc` not found.

- [ ] **Step 3: Implement event/state/bloc**

`pin_event.dart`:

```dart
part of 'pin_bloc.dart';

sealed class PinEvent {
  const PinEvent();
}

class PinDigitPressed extends PinEvent {
  final String digit;
  const PinDigitPressed(this.digit);
}

class PinBackspace extends PinEvent {
  const PinBackspace();
}

class PinCleared extends PinEvent {
  const PinCleared();
}

class PinLockoutTicked extends PinEvent {
  const PinLockoutTicked();
}
```

`pin_state.dart`:

```dart
part of 'pin_bloc.dart';

enum PinMode { setup, unlock }

enum PinPhase { entering, confirming, success, mismatch, error, locked }

class PinState {
  final String entered;
  final String firstEntry;
  final PinMode mode;
  final PinPhase phase;
  final Duration lockoutRemaining;
  final String? errorText;
  final PinUserRecord? unlockedUser;

  const PinState({
    required this.entered,
    required this.firstEntry,
    required this.mode,
    required this.phase,
    required this.lockoutRemaining,
    this.errorText,
    this.unlockedUser,
  });

  factory PinState.initial(PinMode mode) => PinState(
        entered: '', firstEntry: '', mode: mode,
        phase: PinPhase.entering, lockoutRemaining: Duration.zero,
      );

  PinState copyWith({
    String? entered,
    String? firstEntry,
    PinPhase? phase,
    Duration? lockoutRemaining,
    String? errorText,
    bool clearError = false,
    PinUserRecord? unlockedUser,
  }) =>
      PinState(
        entered: entered ?? this.entered,
        firstEntry: firstEntry ?? this.firstEntry,
        mode: mode,
        phase: phase ?? this.phase,
        lockoutRemaining: lockoutRemaining ?? this.lockoutRemaining,
        errorText: clearError ? null : (errorText ?? this.errorText),
        unlockedUser: unlockedUser ?? this.unlockedUser,
      );
}
```

`pin_bloc.dart`:

```dart
import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:bloc/bloc.dart';

part 'pin_event.dart';
part 'pin_state.dart';

typedef EnrollTokens = ({String access, String refresh, String tenantId});

class PinBloc extends Bloc<PinEvent, PinState> {
  final PinVaultService vault;
  final CacheStorage cache;
  final AuthBloc authBloc;
  final PinMode mode;
  final User? enrollUser;
  final EnrollTokens? enrollTokens;

  Timer? _lockTimer;

  PinBloc({
    required this.vault,
    required this.cache,
    required this.authBloc,
    required this.mode,
    this.enrollUser,
    this.enrollTokens,
  }) : super(PinState.initial(mode)) {
    on<PinDigitPressed>(_onDigit);
    on<PinBackspace>(_onBackspace);
    on<PinCleared>(_onCleared);
    on<PinLockoutTicked>(_onTick);
    if (mode == PinMode.unlock) {
      _initLockout();
    }
  }

  Future<void> _initLockout() async {
    final remaining = await vault.lockoutRemaining();
    if (remaining > Duration.zero) {
      emit(state.copyWith(phase: PinPhase.locked, lockoutRemaining: remaining));
      _startLockTimer();
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const PinLockoutTicked());
    });
  }

  void _onTick(PinLockoutTicked e, Emitter<PinState> emit) {
    final next = state.lockoutRemaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      _lockTimer?.cancel();
      emit(state.copyWith(
          phase: PinPhase.entering, lockoutRemaining: Duration.zero));
    } else {
      emit(state.copyWith(lockoutRemaining: next));
    }
  }

  Future<void> _onDigit(PinDigitPressed e, Emitter<PinState> emit) async {
    if (state.phase == PinPhase.locked || state.entered.length >= 4) return;
    final entered = state.entered + e.digit;
    emit(state.copyWith(entered: entered, clearError: true, phase: PinPhase.entering));
    if (entered.length == 4) {
      if (mode == PinMode.setup) {
        await _handleSetup(entered, emit);
      } else {
        await _handleUnlock(entered, emit);
      }
    }
  }

  void _onBackspace(PinBackspace e, Emitter<PinState> emit) {
    if (state.entered.isEmpty) return;
    emit(state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
        clearError: true));
  }

  void _onCleared(PinCleared e, Emitter<PinState> emit) {
    emit(state.copyWith(entered: '', clearError: true));
  }

  Future<void> _handleSetup(String pin, Emitter<PinState> emit) async {
    if (state.firstEntry.isEmpty) {
      emit(state.copyWith(firstEntry: pin, entered: '', phase: PinPhase.confirming));
      return;
    }
    if (pin != state.firstEntry) {
      emit(state.copyWith(
          phase: PinPhase.mismatch, entered: '', firstEntry: '',
          errorText: 'PINs did not match. Try again.'));
      return;
    }
    if (await vault.isPinTaken(pin)) {
      emit(state.copyWith(
          phase: PinPhase.error, entered: '', firstEntry: '',
          errorText: 'This PIN is already in use. Choose another.'));
      return;
    }
    final u = enrollUser;
    final t = enrollTokens;
    if (u == null || t == null) {
      emit(state.copyWith(phase: PinPhase.error, errorText: 'Setup unavailable.'));
      return;
    }
    final salt = PinHasher.generateSalt();
    final now = DateTime.now().toIso8601String();
    await vault.enrollUser(PinUserRecord(
      userId: u.id ?? '',
      businessId: u.businessId ?? '',
      tenantId: t.tenantId,
      fullName: u.fullName ?? '',
      role: u.role ?? '',
      phone: u.phone ?? '',
      pinSalt: salt,
      pinHash: PinHasher.hashPin(pin, salt),
      accessToken: t.access,
      refreshToken: t.refresh,
      profileJson: u.toJson(),
      enrolledAt: now,
      lastUnlockAt: now,
    ));
    emit(state.copyWith(phase: PinPhase.success));
  }

  Future<void> _handleUnlock(String pin, Emitter<PinState> emit) async {
    final match = await vault.findUserByPin(pin);
    if (match == null) {
      await vault.recordFailedAttempt();
      final remaining = await vault.lockoutRemaining();
      if (remaining > Duration.zero) {
        emit(state.copyWith(
            phase: PinPhase.locked, entered: '', lockoutRemaining: remaining));
        _startLockTimer();
      } else {
        emit(state.copyWith(
            phase: PinPhase.mismatch, entered: '',
            errorText: 'Incorrect PIN. Try again.'));
      }
      return;
    }
    await cache.save(Constants.authToken, match.accessToken);
    await cache.save(Constants.refreshToken, match.refreshToken);
    await cache.save(Constants.xTenantID, match.tenantId);
    authBloc.add(OnLoadProfileEvent(
        user: User.fromJson(match.profileJson)));
    emit(state.copyWith(phase: PinPhase.success, unlockedUser: match));
  }

  @override
  Future<void> close() {
    _lockTimer?.cancel();
    return super.close();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/pin/pin_bloc_test.dart`
Expected: PASS (all 3).

- [ ] **Step 5: Commit**

```bash
git add lib/features/pin/presentation/bloc/ test/features/pin/pin_bloc_test.dart
git commit -m "feat(pin): add PinBloc for setup and unlock flows"
```

---

### Task 6: Bloc provider + router cases for PIN screens

**Files:**
- Modify: `lib/config/providers/feature_bloc_providers.dart`
- Modify: `lib/config/router/app_router.dart`

**Interfaces:**
- Consumes: `PinBloc`, `PinMode`, `EnrollTokens` (Task 5); `getIt<PinVaultService>()`, `getIt<CacheStorage>()`, `getIt<AuthBloc>()`.
- Produces:
  - `FeatureBlocProviders.pinSetup({required Widget child, required User user, required EnrollTokens tokens})`
  - `FeatureBlocProviders.pinUnlock({required Widget child})`
  - Router cases for `RouteStrings.pinSetupScreen` (args: `{'user': User, 'tokens': EnrollTokens}`) and `RouteStrings.pinUnlockScreen`.

This task depends on the screen widgets (Tasks 7–8). Implement it together with whichever screen task lands first; the screens import these providers. (Listed separately so the wiring is reviewed on its own.)

- [ ] **Step 1: Add provider methods**

In `lib/config/providers/feature_bloc_providers.dart` add imports:

```dart
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
```

Add methods inside the class:

```dart
  static Widget pinSetup({
    required Widget child,
    required User user,
    required EnrollTokens tokens,
  }) {
    return BlocProvider(
      create: (_) => PinBloc(
        vault: getIt<PinVaultService>(),
        cache: getIt<CacheStorage>(),
        authBloc: getIt<AuthBloc>(),
        mode: PinMode.setup,
        enrollUser: user,
        enrollTokens: tokens,
      ),
      child: child,
    );
  }

  static Widget pinUnlock({required Widget child}) {
    return BlocProvider(
      create: (_) => PinBloc(
        vault: getIt<PinVaultService>(),
        cache: getIt<CacheStorage>(),
        authBloc: getIt<AuthBloc>(),
        mode: PinMode.unlock,
      ),
      child: child,
    );
  }
```

- [ ] **Step 2: Add router cases**

In `lib/config/router/app_router.dart` add imports for `PinSetupScreen`, `PinUnlockScreen` (Tasks 7–8) and `User`/`EnrollTokens`, then add cases before `default:`:

```dart
      case RouteStrings.pinSetupScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          FeatureBlocProviders.pinSetup(
            user: args['user'] as User,
            tokens: args['tokens'] as EnrollTokens,
            child: const PinSetupScreen(),
          ),
          settings,
        );

      case RouteStrings.pinUnlockScreen:
        return _buildRoute(
          FeatureBlocProviders.pinUnlock(child: const PinUnlockScreen()),
          settings,
        );
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/config`
Expected: No errors once Tasks 7–8 screens exist.

- [ ] **Step 4: Commit**

```bash
git add lib/config/providers/feature_bloc_providers.dart lib/config/router/app_router.dart
git commit -m "feat(pin): wire PIN screen providers and routes"
```

---

### Task 7: PIN Setup screen UI (frontend-design)

**Files:**
- Create: `lib/features/pin/presentation/pin_setup_screen.dart`
- Create (as needed): `lib/features/pin/presentation/widgets/pin_dots.dart`, `pin_keypad.dart`, `desktop_pin_layout.dart`

**REQUIRED SUB-SKILL:** Invoke the **frontend-design** skill to design this screen. The functional contract below is fixed; aesthetics (typography, spacing, motion, brand treatment) are frontend-design's job, matching the existing splash/login visual language (`AppTextStyles`, `context.appColors`, `mAnimate`).

**Functional contract:**
- `StatelessWidget` reading `PinBloc` via `BlocConsumer<PinBloc, PinState>`.
- Two-step copy driven by `state.phase`: `entering` → title "Create your PIN"; `confirming` → "Confirm your PIN".
- Render 4 dots from `state.entered.length`; numeric keypad 0–9 + backspace dispatching `PinDigitPressed`/`PinBackspace`.
- Show `state.errorText` on `mismatch`/`error`.
- On `phase == success` → `Navigator.pushNamedAndRemoveUntil(RouteStrings.mainScreen, (_) => false)`.
- Responsive: `LayoutBuilder` — phone = centered column; desktop (width ≥ 900) = split layout reusing the login brand-panel idiom (`desktop_login_brand_panel.dart` as reference) with the pad on one side. Desktop also accepts physical keyboard via a `Focus`/`KeyboardListener` mapping digit keys + backspace to the same events.

- [ ] **Step 1: Invoke frontend-design and build the screen + widgets**

Build `PinSetupScreen` and the shared `PinDots`/`PinKeypad` widgets per the contract. Keep `PinDots` and `PinKeypad` reusable (Task 8 reuses them).

- [ ] **Step 2: Smoke test the widget**

Create `test/features/pin/pin_setup_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_setup_screen.dart';

class _FakePinBloc extends Mock implements PinBloc {}

void main() {
  testWidgets('renders Create your PIN title in entering phase', (tester) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.setup));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<PinBloc>.value(value: bloc, child: const PinSetupScreen()),
    ));
    expect(find.textContaining('PIN'), findsWidgets);
  });
}
```

- [ ] **Step 3: Run test**

Run: `flutter test test/features/pin/pin_setup_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/pin/presentation/ test/features/pin/pin_setup_screen_test.dart
git commit -m "feat(pin): add PIN setup screen (mobile + desktop)"
```

---

### Task 8: PIN Unlock screen UI (frontend-design)

**Files:**
- Create: `lib/features/pin/presentation/pin_unlock_screen.dart`
- Reuse: `widgets/pin_dots.dart`, `pin_keypad.dart` from Task 7

**REQUIRED SUB-SKILL:** Invoke the **frontend-design** skill. Functional contract fixed; aesthetics match the splash brand treatment (logo mark + glow).

**Functional contract:**
- `BlocConsumer<PinBloc, PinState>` in unlock mode.
- Brand/logo header (reuse `AmanaPosLogoMark`), 4 dots, numeric keypad.
- `phase == locked` → disable keypad, show countdown from `state.lockoutRemaining` ("Try again in 0:30").
- `phase == mismatch` → shake the dots + show `errorText`, then allow retry.
- `phase == success` → `Navigator.pushNamedAndRemoveUntil(RouteStrings.mainScreen, (_) => false)`.
- Always-visible footer link **"Forgot PIN? Use a different account"** → `Navigator.pushNamedAndRemoveUntil(RouteStrings.login, (_) => false)`.
- Responsive mobile + desktop (desktop centered card, physical-keyboard digit entry).

- [ ] **Step 1: Invoke frontend-design and build the screen**

- [ ] **Step 2: Smoke test**

Create `test/features/pin/pin_unlock_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_unlock_screen.dart';

class _FakePinBloc extends Mock implements PinBloc {}

void main() {
  testWidgets('shows forgot-pin link', (tester) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.unlock));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<PinBloc>.value(value: bloc, child: const PinUnlockScreen()),
    ));
    expect(find.textContaining('account'), findsWidgets);
  });
}
```

- [ ] **Step 3: Run test**

Run: `flutter test test/features/pin/pin_unlock_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/pin/presentation/pin_unlock_screen.dart test/features/pin/pin_unlock_screen_test.dart
git commit -m "feat(pin): add PIN unlock screen (mobile + desktop)"
```

---

### Task 9: Route to PIN setup after a full login

**Files:**
- Modify: `lib/features/login/presentation/login_screen.dart:163-173`

**Interfaces:**
- Consumes: `PinVaultService` (`getIt`), the freshly-logged-in `User` + tokens. The login already stored tokens (`auth_token`/`refresh_token`) and the active `x_tenant_iD` is resolved by `AuthBloc.OnLoadBusinessEvent`. For setup we read them back from `CacheStorage`.

- [ ] **Step 1: Update the `competed` navigation block**

Replace the body of the `if (state.loginStatus == LoginStatus.competed)` block in `_handleLoginState` with an async enrollment check:

```dart
      if (state.loginStatus == LoginStatus.competed) {
        () async {
          final vault = getIt<PinVaultService>();
          final cache = getIt<CacheStorage>();
          final profile = await cache.getTypedObject<User>(
            Constants.cachedProfile,
            (json) => User.fromJson(json),
          );
          final userId = profile?.id ?? '';
          final alreadyEnrolled =
              userId.isNotEmpty && await vault.isUserEnrolled(userId);
          if (!mounted) return;

          if (profile != null && !alreadyEnrolled) {
            final access = await cache.read(Constants.authToken) ?? '';
            final refresh = await cache.read(Constants.refreshToken) ?? '';
            final tenantId = await cache.read(Constants.xTenantID) ?? '';
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.pinSetupScreen,
              (route) => false,
              arguments: {
                'user': profile,
                'tokens': (access: access, refresh: refresh, tenantId: tenantId),
              },
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.mainScreen,
              (route) => false,
            );
          }
        }();
        context.read<LoginBloc>().add(const OnResetEvent());
        return;
      }
```

Add imports at top of `login_screen.dart` if missing:

```dart
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
```

**Note on tenant timing:** `x_tenant_iD` is written by `AuthBloc._onLoadBusinessEvent` after profile load. If empty at setup time, the unlock-time `OnLoadProfileEvent` re-resolves business and re-writes `x_tenant_iD`, so an empty tenant at enrollment is non-fatal — it gets corrected on next business load. Acceptable for MVP.

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/login/presentation/login_screen.dart`
Expected: No errors.

- [ ] **Step 3: Manual smoke (documented)**

Run the app, complete an OTP/password login on a fresh device → expect routing to the PIN setup screen; complete setup → main screen.

- [ ] **Step 4: Commit**

```bash
git add lib/features/login/presentation/login_screen.dart
git commit -m "feat(pin): route to PIN setup after first full login"
```

---

### Task 10: Splash routes to unlock when a vault exists

**Files:**
- Modify: `lib/features/splash/domain/blocs/splash_bloc.dart`
- Modify: `lib/features/splash/domain/blocs/splash_state.dart` (add `pinLocked` status)
- Modify: `lib/features/splash/presentation/splash_screen.dart` (handle new status)
- Modify: `lib/config/providers/feature_bloc_providers.dart` (`splash(...)` now needs `PinVaultService`)
- Test: `test/features/splash/splash_bloc_test.dart`

**Interfaces:**
- Consumes: `PinVaultService.hasAnyEnrolled()`.
- Produces: `SplashStatus.pinLocked` enum value; `SplashBloc({required CacheStorage cacheStorage, required PinVaultService vault})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';

class _MockCache extends Mock implements CacheStorage {}
class _MockVault extends Mock implements PinVaultService {}

void main() {
  late _MockCache cache;
  late _MockVault vault;

  setUp(() {
    cache = _MockCache();
    vault = _MockVault();
  });

  blocTest<SplashBloc, SplashState>(
    'routes to pinLocked when vault has users',
    build: () {
      when(() => cache.getValue(Constants.authToken)).thenAnswer((_) async => 'tok');
      when(() => vault.hasAnyEnrolled()).thenAnswer((_) async => true);
      return SplashBloc(cacheStorage: cache, vault: vault);
    },
    act: (b) => b.add(const SplashStarted()),
    wait: const Duration(seconds: 2),
    expect: () => [
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.loading),
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.pinLocked),
    ],
  );

  blocTest<SplashBloc, SplashState>(
    'routes to unauthenticated when no token and empty vault',
    build: () {
      when(() => cache.getValue(Constants.authToken)).thenAnswer((_) async => null);
      when(() => vault.hasAnyEnrolled()).thenAnswer((_) async => false);
      return SplashBloc(cacheStorage: cache, vault: vault);
    },
    act: (b) => b.add(const SplashStarted()),
    wait: const Duration(seconds: 2),
    expect: () => [
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.loading),
      isA<SplashState>()
          .having((s) => s.status, 'status', SplashStatus.unauthenticated),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/splash/splash_bloc_test.dart`
Expected: FAIL — `vault` param / `pinLocked` not defined.

- [ ] **Step 3: Add `pinLocked` to `SplashStatus`**

In `splash_state.dart`, add `pinLocked` to the `SplashStatus` enum.

- [ ] **Step 4: Update `SplashBloc`**

Add field + constructor param and branch. Replace the decision tail of `_onSplashStarted`:

```dart
      final token = await cacheStorage.getValue(Constants.authToken);
      final hasVault = await vault.hasAnyEnrolled();

      final SplashStatus next;
      if (hasVault) {
        next = SplashStatus.pinLocked;
      } else if (token != null && token.toString().trim().isNotEmpty) {
        next = SplashStatus.authenticated;
      } else {
        next = SplashStatus.unauthenticated;
      }

      emit(state.copyWith(status: next));
```

Add field/constructor:

```dart
  final PinVaultService vault;

  SplashBloc({
    required this.cacheStorage,
    required this.vault,
  }) : super(const SplashState.initial()) {
    on<SplashStarted>(_onSplashStarted);
  }
```

Add import: `import 'package:amana_pos/features/pin/data/pin_vault_service.dart';`

- [ ] **Step 5: Handle `pinLocked` in splash screen**

In `splash_screen.dart` listener, add a case:

```dart
          case SplashStatus.pinLocked:
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.pinUnlockScreen,
              (route) => false,
            );
            break;
```

- [ ] **Step 6: Update provider**

In `feature_bloc_providers.dart`, `splash(...)`:

```dart
  static Widget splash({required Widget child}) {
    return BlocProvider(
      create: (_) => SplashBloc(
        cacheStorage: getIt<CacheStorage>(),
        vault: getIt<PinVaultService>(),
      ),
      child: child,
    );
  }
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/features/splash/splash_bloc_test.dart`
Expected: PASS (both).

- [ ] **Step 8: Commit**

```bash
git add lib/features/splash/ lib/config/providers/feature_bloc_providers.dart test/features/splash/splash_bloc_test.dart
git commit -m "feat(pin): splash routes to unlock when a PIN vault exists"
```

---

### Task 11: Background-timeout lock (`AppLockObserver`)

**Files:**
- Create: `lib/common/services/app_lock_observer.dart`
- Modify: `lib/app.dart` (wrap `child` in the MaterialApp `builder` with the observer widget)

**Interfaces:**
- Consumes: `PinVaultService` (`getIt`), `Constants.navigatorKey`, `RouteStrings.pinUnlockScreen`, `AppRouter.currentRouteName`.
- Produces: `class AppLockObserver extends StatefulWidget` wrapping a child; locks on resume after 2 min.

- [ ] **Step 1: Implement the observer**

```dart
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';

class AppLockObserver extends StatefulWidget {
  final Widget child;
  const AppLockObserver({super.key, required this.child});

  @override
  State<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends State<AppLockObserver>
    with WidgetsBindingObserver {
  static const _timeout = Duration(minutes: 2);
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || DateTime.now().difference(since) < _timeout) return;

    // Don't stack the lock screen if already on an auth surface.
    final current = AppRouter.currentRouteName;
    if (current == RouteStrings.pinUnlockScreen ||
        current == RouteStrings.pinSetupScreen ||
        current == RouteStrings.login ||
        current == RouteStrings.splash) {
      return;
    }

    if (await getIt<PinVaultService>().hasAnyEnrolled()) {
      Constants.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteStrings.pinUnlockScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: Wrap the app content**

In `lib/app.dart`, in the MaterialApp `builder`, wrap the returned `MediaQuery` child with `AppLockObserver`:

```dart
                builder: (context, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: Motion.animationsEnabled,
                    builder: (context, enabled, _) {
                      var data = MediaQuery.of(context)
                          .copyWith(disableAnimations: !enabled);
                      if (Platform.isMacOS || Platform.isWindows) {
                        data = data.copyWith(textScaler: TextScaler.noScaling);
                      }
                      return MediaQuery(
                        data: data,
                        child: AppLockObserver(child: child!),
                      );
                    },
                  );
                },
```

Add import: `import 'package:amana_pos/common/services/app_lock_observer.dart';`

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/common/services/app_lock_observer.dart lib/app.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/common/services/app_lock_observer.dart lib/app.dart
git commit -m "feat(pin): lock app on resume after 2-minute background"
```

---

### Task 12: Same-business no-wipe refinement in `AuthBloc`

**Files:**
- Modify: `lib/common/auth_bloc/auth_bloc.dart` (the `event.user` branch at `:45-58` and the fresh-profile branch at `:89-110`; add a `_currentBusinessId` field near `:24`)
- Test: `test/common/auth_bloc/auth_bloc_wipe_test.dart`

**Interfaces:**
- Behavior change: wipe offline cache only when **businessId** changes; bump `sessionId` (via `_emitProfileLoaded(userSwitched:)`) when **user id** changes.
- Consumes existing: `offlineLocalCache.clearAllOnLogout()`, `User.businessId`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}
class _MockBusinessUseCase extends Mock implements BusinessUseCase {}
class _MockOfflineCache extends Mock implements OfflineLocalCache {}
class _MockOfflineStatusBloc extends Mock implements OfflineStatusBloc {}

void main() {
  late _MockLoginUseCase login;
  late _MockBusinessUseCase business;
  late _MockOfflineCache offline;
  late _MockOfflineStatusBloc offlineStatus;

  setUp(() {
    login = _MockLoginUseCase();
    business = _MockBusinessUseCase();
    offline = _MockOfflineCache();
    offlineStatus = _MockOfflineStatusBloc();
    when(() => offline.clearAllOnLogout()).thenAnswer((_) async {});
    when(() => offline.getBusinesses()).thenAnswer((_) async => []);
  });

  AuthBloc make() => AuthBloc(
        useCase: login, businessUseCase: business,
        offlineLocalCache: offline, offlineStatusBloc: offlineStatus,
      );

  const u1 = User(id: 'u1', businessId: 'b1', role: 'owner');
  const u2 = User(id: 'u2', businessId: 'b1', role: 'cashier');
  const u3 = User(id: 'u3', businessId: 'b2', role: 'owner');

  blocTest<AuthBloc, AuthState>(
    'same business different user does NOT wipe',
    build: make,
    act: (b) async {
      b.add(OnLoadProfileEvent(user: u1));
      await Future.delayed(const Duration(milliseconds: 10));
      b.add(OnLoadProfileEvent(user: u2));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verifyNever(() => offline.clearAllOnLogout()),
  );

  blocTest<AuthBloc, AuthState>(
    'different business DOES wipe',
    build: make,
    act: (b) async {
      b.add(OnLoadProfileEvent(user: u1));
      await Future.delayed(const Duration(milliseconds: 10));
      b.add(OnLoadProfileEvent(user: u3));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => offline.clearAllOnLogout()).called(1),
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/common/auth_bloc/auth_bloc_wipe_test.dart`
Expected: FAIL — current logic wipes on user-id change (first test fails).

- [ ] **Step 3: Refactor the wipe decision**

Add near the other private fields (`:24`):

```dart
  String? _currentBusinessId;
```

In `_onLoadProfile`, the `event.user != null` branch — replace the `isDifferentUser`/wipe block (`:46-56`) with:

```dart
        final incomingId = _userIdFrom(event.user!);
        final incomingBusiness = event.user!.businessId;

        final isDifferentUser = _loggedOut ||
            (_currentUserXTenantID != null &&
                _currentUserXTenantID != incomingId);
        final isDifferentBusiness = _loggedOut ||
            (_currentBusinessId != null &&
                _currentBusinessId != incomingBusiness);
        _loggedOut = false;

        if (isDifferentBusiness) {
          await offlineLocalCache.clearAllOnLogout();
        }

        _currentUserXTenantID = incomingId;
        _currentBusinessId = incomingBusiness;
        _emitProfileLoaded(emit, event.user!, userSwitched: isDifferentUser);
        add(OnLoadBusinessEvent());
        return;
```

In the fresh-profile branch (`:89-110`), apply the same split: wipe on `isDifferentBusiness` (compare `fresh.user!.businessId` to `_currentBusinessId`), bump session on `isDifferentUser`, and set `_currentBusinessId = incomingBusiness;` alongside `_currentUserXTenantID`.

In `_onLogout` (`:163`) and `close()` (`:321`) reset `_currentBusinessId = null;`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/common/auth_bloc/auth_bloc_wipe_test.dart`
Expected: PASS (both).

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: All tests pass; no analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add lib/common/auth_bloc/auth_bloc.dart test/common/auth_bloc/auth_bloc_wipe_test.dart
git commit -m "feat(pin): wipe offline cache only when business changes, not on PIN user switch"
```

---

## Self-Review

**Spec coverage:**
- Storage / vault shape → Tasks 2–3. ✅
- PBKDF2 hashing + `crypto` dep → Task 1. ✅
- PIN uniqueness at setup → Task 3 (`isPinTaken`) + Task 5 (setup branch). ✅
- `PinVaultService` API → Task 3. ✅
- `PinBloc` + token swap + `OnLoadProfileEvent` → Task 5. ✅
- `AppLockController` (2-min background) → Task 11. ✅
- Enrollment after login → Task 9. ✅
- Splash → unlock routing → Task 10. ✅
- Unlock match/lockout/forgot-pin → Tasks 5, 8. ✅
- Add-another-user via forgot link → Task 8 (link → login → Task 9). ✅
- Same-business no-wipe refinement → Task 12. ✅
- Two responsive screens via frontend-design → Tasks 7–8. ✅
- Routes/DI/providers → Tasks 4, 6. ✅
- Testing strategy → tests in Tasks 1–3, 5, 10, 12 + smoke 7–8. ✅
- Lockout 5/30s escalating, 4-digit, 2-min, biometrics-none, no user list → Global Constraints + enforced in Tasks 3, 5, 8, 11. ✅
- Sale attribution → explicitly out of scope (spec Non-Goals). ✅

**Placeholder scan:** No TBD/TODO; every code step has full code. ✅

**Type consistency:** `PinVaultService` method names, `PinUserRecord` fields, `PinBloc` constructor params, `EnrollTokens` record type, and `SplashStatus.pinLocked` are used consistently across Tasks 3–12. ✅

## Execution Notes / Ordering

Implement in numeric order. Tasks 7 and 8 (UI) depend on Task 5 (`PinBloc`) and Task 6 (providers/routes); Task 6's router cases reference the Task 7/8 screen classes, so land Task 6 immediately before or together with Tasks 7–8 to keep the build green. Run `flutter analyze` after Task 6 only once the screens exist.
