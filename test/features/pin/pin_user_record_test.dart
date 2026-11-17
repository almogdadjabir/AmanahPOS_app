import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';

void main() {
  PinUserRecord sample() => PinUserRecord(
    userId: 'u1',
    businessId: 'b1',
    tenantId: 't1',
    fullName: 'Cashier One',
    role: 'cashier',
    phone: '+249...',
    pinSalt: 'salt',
    pinHash: 'hash',
    accessToken: 'acc',
    refreshToken: 'ref',
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
