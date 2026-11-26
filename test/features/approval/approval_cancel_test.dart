import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/permissions/discount_access.dart';
import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/approval/domain/owner_approval_service.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/sales_history/domain/cancel_sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/sale_applier_test.dart' show feedSale;
import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Cache extends Mock implements CacheStorage {}

PinUserRecord _user(String id, String role, String pin) {
  final salt = PinHasher.generateSalt();
  return PinUserRecord(
    userId: id,
    businessId: 'b',
    tenantId: 't',
    fullName: id,
    role: role,
    phone: '1',
    pinSalt: salt,
    pinHash: PinHasher.hashPin(pin, salt),
    accessToken: '',
    refreshToken: '',
    profileJson: const {},
    enrolledAt: 'x',
    lastUnlockAt: 'x',
  );
}

PinVaultService _vault(List<PinUserRecord> users) {
  final cache = _Cache();
  Object? store = {'users': users.map((u) => u.toJson()).toList()};
  when(() => cache.getObject('pin_vault')).thenAnswer((_) async => store);
  when(() => cache.saveObject('pin_vault', any())).thenAnswer((i) async {
    store = i.positionalArguments[1];
    return true;
  });
  return PinVaultService(cache);
}

const _sale = '55555555-5555-4555-8555-555555555555';

void main() {
  group('owner approval', () {
    test('owner PIN approves, cashier PIN does not, 5 wrong lock for 30s', () async {
      var now = DateTime(2026, 1, 1, 9);
      final s = OwnerApprovalService(
        _vault([_user('o', 'owner', '1234'), _user('c', 'cashier', '9999')]),
        now: () => now,
      );
      expect(await s.check('1234'), isA<Approved>());
      // a cashier's own PIN is not an approval
      final w = await s.check('9999');
      expect(w, isA<WrongPin>());
      expect((w as WrongPin).triesLeft, 4);
      await s.check('0000');
      await s.check('0000');
      await s.check('0000');
      final l = await s.check('0000');
      expect(l, isA<Locked>());
      // right PIN is refused while locked
      expect(await s.check('1234'), isA<Locked>());
      now = now.add(const Duration(seconds: 31));
      expect(await s.check('1234'), isA<Approved>());
    });

    test('no owner PIN saved on the phone', () async {
      final s = OwnerApprovalService(_vault([_user('c', 'cashier', '1111')]));
      expect(await s.check('1111'), isA<NoOwnerPin>());
    });
  });

  group('cashier discount access', () {
    AppPermissions p(String role) =>
        AppPermissions.from(businessType: 'shop', userRole: role);
    test('owner and manager direct, cashier follows the mode', () {
      for (final m in CashierDiscountMode.values) {
        final f = BusinessFeatures(cashierDiscount: m);
        expect(discountAccess(p('owner'), f), DiscountAccess.direct);
        expect(discountAccess(p('manager'), f), DiscountAccess.direct);
      }
      expect(
        discountAccess(p('cashier'), const BusinessFeatures()),
        DiscountAccess.none,
      );
      expect(
        discountAccess(
          p('cashier'),
          const BusinessFeatures(cashierDiscount: CashierDiscountMode.approval),
        ),
        DiscountAccess.approval,
      );
      expect(
        discountAccess(
          p('cashier'),
          const BusinessFeatures(cashierDiscount: CashierDiscountMode.free),
        ),
        DiscountAccess.direct,
      );
    });

    test('server value is read, unknown means off', () {
      expect(
        BusinessFeatures.fromJson({'cashier_discount_mode': 'approval'})
            .cashierDiscount,
        CashierDiscountMode.approval,
      );
      expect(
        BusinessFeatures.fromJson({'cashier_discount_mode': 'x'}).cashierDiscount,
        CashierDiscountMode.off,
      );
      expect(BusinessFeatures.fromJson({}).cashierDiscount, CashierDiscountMode.off);
    });
  });

  group('cancel sale', () {
    late SaleFixture f;
    late CancelSaleService svc;
    setUp(() async {
      f = await SaleFixture.on(await openTestDb());
      svc = CancelSaleService(writer: f.writer, now: () => f.clock);
      await f.db.transaction(
        (t) => SaleApplier().apply(
          t,
          PullChange(
            seq: 1,
            entity: 'sale',
            op: 'upsert',
            id: _sale,
            version: 1,
            data: feedSale(),
            shopId: kShop,
          ),
        ),
      );
    });
    tearDown(() async {
      f.notifier.dispose();
      await f.db.close();
    });

    Future<String> status() async =>
        (await f.db.query('sales', where: 'id = ?', whereArgs: [_sale]))
                .single['status']
            as String;

    test('cancels once: status, one sale.cancel outbox row with the reason', () async {
      expect(
        await svc.cancel(saleId: _sale, reason: '  changed mind  '),
        CancelOutcome.done,
      );
      expect(await status(), 'cancelled');
      final rows = await f.db.query('outbox');
      expect(rows, hasLength(1));
      final e = OutboxEntry.fromRow(rows.single);
      expect(e.entity, 'sale');
      expect(e.op, 'cancel');
      expect(e.payload['reason'], 'changed mind');
      // second time: refused, nothing more queued
      expect(await svc.cancel(saleId: _sale), CancelOutcome.notAllowed);
      expect(await f.db.query('outbox'), hasLength(1));
    });

    test('a sale with a refund cannot be cancelled', () async {
      await f.db.insert('sale_refunds', {
        'id': 'r1',
        'sale_id': _sale,
        'shop_id': kShop,
        'total': '1.00',
        'occurred_at': '2026-11-16T09:30:00Z',
        'method': 'cash',
        'reference': 'r1',
        'sync_state': 'pending',
        'json': '{"items":[]}',
      });
      expect(await svc.cancel(saleId: _sale), CancelOutcome.hasRefunds);
      expect(await status(), isNot('cancelled'));
      expect(await f.db.query('outbox'), isEmpty);
    });

    test('unknown sale', () async {
      expect(await svc.cancel(saleId: 'nope'), CancelOutcome.notFound);
    });

    test('reason is cut to 500 characters, blank becomes none', () {
      expect(CancelSaleService.cutReason('   '), isNull);
      expect(CancelSaleService.cutReason('a' * 600)!.length, 500);
    });

    test('server rejecting the cancel puts the sale back', () async {
      await svc.cancel(saleId: _sale);
      final e = OutboxEntry.fromRow((await f.db.query('outbox')).single);
      await f.db.transaction(
        (t) => SaleApplier().onPushResult(
          t,
          e,
          PushResult(
            mutationId: e.mutationId,
            status: PushStatus.rejected,
            entityId: _sale,
            code: 'validation_error',
          ),
        ),
      );
      expect(await status(), 'completed');
    });
  });
}
