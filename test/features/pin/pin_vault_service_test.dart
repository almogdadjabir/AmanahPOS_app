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
