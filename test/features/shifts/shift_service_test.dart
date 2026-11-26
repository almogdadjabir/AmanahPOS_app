import 'dart:convert';

import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/domain/shift.dart';
import 'package:amana_pos/features/shifts/domain/shift_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

BigInt c(String s) => Cents.parse(s)!;

const owner = ShiftActor(id: kCashier, name: 'Sara', canManage: true);
const cashier = ShiftActor(id: kP1, name: 'Omar', canManage: false);

void main() {
  late SaleFixture f;
  late BusinessFeatures features;
  ShiftActor? actor;
  String? shop;
  late ShiftService svc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    features = const BusinessFeatures(
      shiftsMode: ShiftsMode.manual,
      cashDrawerFlag: true,
    );
    actor = owner;
    shop = kShop;
    svc = ShiftService(
      writer: f.writer,
      state: f.state,
      features: () => features,
      actor: () => actor,
      shopId: () => shop,
      now: () => f.clock,
    );
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<List<Map<String, Object?>>> outbox() => f.db.query('outbox');
  Map<String, dynamic> payload(Map<String, Object?> r) =>
      jsonDecode(r['payload_json'] as String) as Map<String, dynamic>;
  ShiftError? err(ShiftResult r) => r is ShiftFailed ? r.error : null;

  group('open', () {
    test('writes the row and one shift.open outbox row', () async {
      final r = await svc.open(openingCash: c('500'));
      expect(r, isA<ShiftDone>());
      final s = (await f.db.query('shifts')).single;
      expect(s['opening_cash'], '500.00');
      expect(s['sync_state'], 'pending');
      expect(s['opened_by_name'], 'Sara');
      expect(s['origin'], 'manual');
      final o = (await outbox()).single;
      expect(o['entity'], 'shift');
      expect(o['op'], 'open');
      expect(o['entity_id'], s['id']);
      final p = payload(o);
      expect(p['shop_id'], kShop);
      expect(p['opening_cash'], '500.00');
      expect(p['origin'], 'manual');
      expect(p['opened_by'], kCashier);
      expect(p['opened_at'], f.clock.toIso8601String());
      expect(p['device_id'], kDevice);
    });

    test('a second open is AlreadyOpen and writes nothing', () async {
      await svc.open(openingCash: c('1'));
      final r = await svc.open(openingCash: c('2'));
      expect(err(r), ShiftError.alreadyOpen);
      expect(await f.db.query('shifts'), hasLength(1));
      expect(await outbox(), hasLength(1));
    });

    test('opening cash defaults to the last count', () async {
      await svc.open(openingCash: c('100'));
      await svc.close(counted: c('130'));
      await svc.open();
      final rows = await f.db.query('shifts', orderBy: 'opened_at');
      expect(rows.map((r) => r['opening_cash']), ['100.00', '130.00']);
    });

    test('rules: off, no session, no shop, cashier, negative', () async {
      features = const BusinessFeatures();
      expect(err(await svc.open()), ShiftError.disabled);
      features = const BusinessFeatures(shiftsMode: ShiftsMode.manual);
      actor = null;
      expect(err(await svc.open()), ShiftError.noSession);
      actor = owner;
      shop = null;
      expect(err(await svc.open()), ShiftError.noShop);
      shop = kShop;
      actor = cashier;
      expect(err(await svc.open()), ShiftError.notAllowed);
      features = const BusinessFeatures(
        shiftsMode: ShiftsMode.manual,
        cashiersMayOperateShifts: true,
      );
      expect(err(await svc.open(openingCash: c('-1'))), ShiftError.amountInvalid);
      expect(await svc.open(openingCash: c('0')), isA<ShiftDone>());
      expect(await outbox(), hasLength(1));
    });

    test('drawer off: no opening cash is stored', () async {
      features = const BusinessFeatures(shiftsMode: ShiftsMode.manual);
      await svc.open(openingCash: c('500'));
      expect((await f.db.query('shifts')).single['opening_cash'], '0.00');
    });

    test('auto origin needs no signed-in user and no permission', () async {
      features = const BusinessFeatures(shiftsMode: ShiftsMode.auto);
      actor = null;
      final at = DateTime.utc(2026, 11, 16, 8);
      final r = await svc.open(origin: ShiftOrigin.auto, at: at);
      expect(r, isA<ShiftDone>());
      final s = (await f.db.query('shifts')).single;
      expect(s['origin'], 'auto');
      expect(s['opened_at'], at.toIso8601String());
      expect(s['opened_by'], isNull);
    });
  });

  group('close', () {
    test('freezes expected, stores the count, enqueues shift.close', () async {
      await svc.open(openingCash: c('500'));
      await f.db.insert('sales', {
        'id': 'sale1', 'shop_id': kShop, 'status': 'completed',
        'subtotal': '100', 'discount': '0', 'tax_amount': '0',
        'net_amount': '100', 'occurred_at': '2026-11-16T09:30:00.000Z',
        'sync_state': 'synced',
      });
      await f.db.insert('sale_payments', {
        'sale_id': 'sale1', 'position': 0, 'method': 'cash', 'amount': '100',
      });
      f.clock = DateTime.utc(2026, 11, 16, 18);
      final r = await svc.close(counted: c('595'), note: 'ok');
      final done = r as ShiftDone;
      expect(done.expected, c('600'));
      expect(done.difference, c('-5'));
      final s = (await f.db.query('shifts')).single;
      expect(s['expected_cash'], '600.00');
      expect(s['counted_cash'], '595.00');
      expect(s['closed_at'], f.clock.toIso8601String());
      expect(s['closed_by_name'], 'Sara');
      final o = (await outbox()).last;
      expect(o['op'], 'close');
      expect((await outbox()).map((r) => r['op']), ['open', 'close']);
      final p = payload(o);
      expect(p['expected_cash'], '600.00');
      expect(p['counted_cash'], '595.00');
      expect(p['note'], 'ok');
    });

    test('no count: needs count and no counted_cash sent', () async {
      await svc.open(openingCash: c('500'));
      await svc.close();
      final s = (await f.db.query('shifts')).single;
      expect(s['counted_cash'], isNull);
      expect(s['expected_cash'], '500.00');
      expect(payload((await outbox()).last).containsKey('counted_cash'),
          isFalse);
    });

    test('drawer off closes as counted zero so it never waits for a count',
        () async {
      features = const BusinessFeatures(shiftsMode: ShiftsMode.manual);
      await svc.open();
      await svc.close();
      final s = (await f.db.query('shifts')).single;
      expect(s['expected_cash'], '0.00');
      expect(s['counted_cash'], '0.00');
    });

    test('not open', () async {
      expect(err(await svc.close(counted: c('1'))), ShiftError.notOpen);
    });

    test('cashier blocked unless allowed', () async {
      await svc.open(openingCash: c('1'));
      actor = cashier;
      expect(err(await svc.close(counted: c('1'))), ShiftError.notAllowed);
    });
  });

  group('count', () {
    test('only for a closed shift without a count, once', () async {
      await svc.open(openingCash: c('500'));
      final id = (await f.db.query('shifts')).single['id'] as String;
      expect(err(await svc.count(id, c('1'))), ShiftError.notCountable);
      await svc.close();
      final r = await svc.count(id, c('498'), note: 'recount') as ShiftDone;
      expect(r.expected, c('500'));
      expect(r.difference, c('-2'));
      expect((await f.db.query('shifts')).single['counted_cash'], '498.00');
      final p = payload((await outbox()).last);
      expect((await outbox()).last['op'], 'count');
      expect(p['counted_cash'], '498.00');
      expect(p['expected_cash'], '500.00');
      expect(err(await svc.count(id, c('1'))), ShiftError.notCountable);
      expect(err(await svc.count('nope', c('1'))), ShiftError.notFound);
    });
  });

  group('movements', () {
    test('pay in and pay out update expected and enqueue', () async {
      await svc.open(openingCash: c('500'));
      final a = await svc.addMovement(
        isPayIn: true, amount: c('50'), reason: 'float');
      expect((a as ShiftDone).expected, c('550'));
      final b = await svc.addMovement(
        isPayIn: false, amount: c('125'), reason: 'supplier');
      expect((b as ShiftDone).expected, c('425'));
      expect(b.exceedsDrawer, isFalse);
      final m = await f.db.query('cash_movements', orderBy: 'occurred_at');
      expect(m.map((r) => r['kind']), ['pay_in', 'pay_out']);
      final o = (await outbox()).last;
      expect(o['entity'], 'cash_movement');
      expect(o['op'], 'create');
      final p = payload(o);
      expect(p['kind'], 'pay_out');
      expect(p['amount'], '125.00');
      expect(p['reason'], 'supplier');
      expect(p['shift_id'], (await f.db.query('shifts')).single['id']);
      expect((await outbox()).map((r) => r['entity']),
          ['shift', 'cash_movement', 'cash_movement']);
    });

    test('a big pay out is allowed and flagged', () async {
      await svc.open(openingCash: c('100'));
      final r = await svc.addMovement(
        isPayIn: false, amount: c('2000'), reason: 'x') as ShiftDone;
      expect(r.exceedsDrawer, isTrue);
      expect(await f.db.query('cash_movements'), hasLength(1));
    });

    test('rules', () async {
      expect(err(await svc.addMovement(
        isPayIn: true, amount: c('1'), reason: 'a')), ShiftError.notOpen);
      await svc.open(openingCash: c('1'));
      expect(err(await svc.addMovement(
        isPayIn: true, amount: BigInt.zero, reason: 'a')),
        ShiftError.amountInvalid);
      expect(err(await svc.addMovement(
        isPayIn: true, amount: c('1'), reason: '  ')),
        ShiftError.reasonRequired);
      features = const BusinessFeatures(shiftsMode: ShiftsMode.manual);
      expect(err(await svc.addMovement(
        isPayIn: true, amount: c('1'), reason: 'a')), ShiftError.drawerOff);
      features = const BusinessFeatures(
        shiftsMode: ShiftsMode.manual, cashDrawerFlag: true);
      actor = cashier; // pay in/out is open to any signed-in user
      expect(await svc.addMovement(
        isPayIn: true, amount: c('1'), reason: 'a'), isA<ShiftDone>());
      actor = null;
      expect(err(await svc.addMovement(
        isPayIn: true, amount: c('1'), reason: 'a')), ShiftError.noSession);
    });

  });
}
