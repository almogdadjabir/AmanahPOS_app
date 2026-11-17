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
      userId: userId,
      businessId: 'b1',
      tenantId: 'b1',
      fullName: 'U',
      role: 'cashier',
      phone: '+1',
      pinSalt: salt,
      pinHash: PinHasher.hashPin(pin, salt),
      accessToken: 'acc',
      refreshToken: 'ref',
      profileJson: {'id': userId},
      enrolledAt: 'n',
      lastUnlockAt: 'n',
    );
  }

  setUp(() {
    cache = _FakeCache();
    store = {};
    when(
      () => cache.getObject('pin_vault'),
    ).thenAnswer((_) async => store['pin_vault']);
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
    expect(
      await service.changePin('ghost', '0000'),
      ChangePinResult.userNotFound,
    );
  });
}
