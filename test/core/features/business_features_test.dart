import 'dart:convert';

import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/support/test_db.dart';

void main() {
  group('BusinessFeatures.fromJson', () {
    test('empty row gives today behaviour: all on, drawer and shifts off', () {
      final f = BusinessFeatures.fromJson(const {});
      expect(f.splitPayments, isTrue);
      expect(f.onAccount, isTrue);
      expect(f.lineDiscount, isTrue);
      expect(f.saleDiscount, isTrue);
      expect(f.stockCount, isTrue);
      expect(f.shiftsMode, ShiftsMode.off);
      expect(f.shiftsEnabled, isFalse);
      expect(f.cashDrawer, isFalse);
      expect(f.shiftsAutoOpen, const ShiftTime(8, 0));
      expect(f.shiftsAutoClose, const ShiftTime(22, 0));
    });

    test('reads the business time zone', () {
      expect(BusinessFeatures.fromJson(const {'timezone': 'Africa/Khartoum'}).timezone, 'Africa/Khartoum');
      expect(BusinessFeatures.fromJson(const {}).timezone, isNull);
    });

    test('bad times fall back to 08:00 and 22:00', () {
      final f = BusinessFeatures.fromJson(const {
        'shifts_auto_open': '25:99',
        'shifts_auto_close': 'late',
      });
      expect(f.shiftsAutoOpen, const ShiftTime(8, 0));
      expect(f.shiftsAutoClose, const ShiftTime(22, 0));
    });

    test('the backend may send seconds', () {
      final f = BusinessFeatures.fromJson(const {
        'shifts_auto_open': '06:05:00',
      });
      expect(f.shiftsAutoOpen, const ShiftTime(6, 5));
    });

    test('reads every switch', () {
      final f = BusinessFeatures.fromJson(const {
        'split_payments_enabled': false,
        'on_account_enabled': false,
        'line_discount_enabled': false,
        'sale_discount_enabled': false,
        'stock_count_enabled': false,
        'shifts_mode': 'manual',
        'cash_drawer_enabled': true,
        'shifts_auto_open': '07:30',
        'shifts_auto_close': '23:15',
        'shifts_cashiers_may_operate': true,
      });
      expect(f.splitPayments, isFalse);
      expect(f.onAccount, isFalse);
      expect(f.lineDiscount, isFalse);
      expect(f.saleDiscount, isFalse);
      expect(f.stockCount, isFalse);
      expect(f.shiftsMode, ShiftsMode.manual);
      expect(f.shiftsAutoOpen, const ShiftTime(7, 30));
      expect(f.shiftsAutoClose, const ShiftTime(23, 15));
      expect(f.cashiersMayOperateShifts, isTrue);
      expect(f.cashDrawer, isTrue);
    });

    test('cash drawer is off while shifts are off, whatever the flag says', () {
      final f = BusinessFeatures.fromJson(const {
        'shifts_mode': 'off',
        'cash_drawer_enabled': true,
      });
      expect(f.cashDrawer, isFalse);
    });

    test('unknown or wrong-typed values fall back to the defaults', () {
      final f = BusinessFeatures.fromJson(const {
        'shifts_mode': 'weekly',
        'split_payments_enabled': 'nope',
        'cash_drawer_enabled': null,
      });
      expect(f.shiftsMode, ShiftsMode.off);
      expect(f.splitPayments, isTrue);
      expect(f.cashDrawer, isFalse);
    });

    test('auto is a shifts mode that counts as enabled', () {
      final f = BusinessFeatures.fromJson(const {'shifts_mode': 'auto'});
      expect(f.shiftsMode, ShiftsMode.auto);
      expect(f.shiftsEnabled, isTrue);
    });
  });

  group('BusinessFeaturesService', () {
    late OfflineDb offline;
    late DbChangeNotifier notifier;
    late BusinessFeaturesService service;

    Future<void> putFeed(Map<String, dynamic> row) async {
      final db = await offline.database;
      await db.insert('synced_entities', {
        'entity': 'business',
        'id': 'b1',
        'version': 1,
        'json': jsonEncode(row),
        'updated_at': '2026-01-01T00:00:00Z',
      });
    }

    setUp(() async {
      offline = await openTestDb();
      notifier = DbChangeNotifier();
      service = BusinessFeaturesService(db: offline, notifier: notifier);
    });

    tearDown(() async {
      await service.dispose();
      notifier.dispose();
      await (await offline.database).close();
    });

    test('no business row yet: defaults', () async {
      final f = await service.load();
      expect(f.splitPayments, isTrue);
      expect(f.shiftsMode, ShiftsMode.off);
      expect(service.current.splitPayments, isTrue);
    });

    test('reads the synced feed row', () async {
      await putFeed({'shifts_mode': 'auto', 'on_account_enabled': false});
      final f = await service.load();
      expect(f.shiftsMode, ShiftsMode.auto);
      expect(f.onAccount, isFalse);
      expect(service.current.onAccount, isFalse);
    });

    test('falls back to the legacy businesses row', () async {
      final db = await offline.database;
      await db.insert('businesses', {
        'id': 'b1',
        'json': jsonEncode({'stock_count_enabled': false}),
      });
      final f = await service.load();
      expect(f.stockCount, isFalse);
    });

    test('emits again when the business table changes', () async {
      await service.load();
      final seen = <bool>[];
      final sub = service.changes.listen((f) => seen.add(f.splitPayments));
      await putFeed({'split_payments_enabled': false});
      notifier.notify({'synced_entities'});
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await sub.cancel();
      expect(seen, contains(false));
      expect(service.current.splitPayments, isFalse);
    });
  });
}
