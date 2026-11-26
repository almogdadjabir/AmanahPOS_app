import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/data/shift_store.dart';
import 'package:amana_pos/features/shifts/domain/shift.dart';
import 'package:amana_pos/features/shifts/domain/shift_reconciler.dart';
import 'package:amana_pos/features/shifts/domain/shift_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

void main() {
  late SaleFixture f;
  late ShiftService svc;
  late ShiftReconciler rec;
  var features = const BusinessFeatures(shiftsMode: ShiftsMode.auto);

  setUp(() async {
    features = const BusinessFeatures(shiftsMode: ShiftsMode.auto);
    f = await SaleFixture.on(await openTestDb());
    svc = ShiftService(
      writer: f.writer,
      state: f.state,
      features: () => features,
      actor: () => null,
      shopId: () => kShop,
      now: () => f.clock,
    );
    rec = ShiftReconciler(
      service: svc,
      db: () async => f.db,
      features: () => features,
      shopId: () => kShop,
      timezone: () async => 'Africa/Khartoum', // UTC+2
      now: () => f.clock,
    );
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<List<Map<String, Object?>>> shifts() =>
      f.db.query('shifts', orderBy: 'opened_at');

  test('inside the window it opens at the scheduled time (business time)',
      () async {
    // 07:30 UTC = 09:30 Khartoum, window opens 08:00 local = 06:00 UTC.
    f.clock = DateTime.utc(2026, 11, 16, 7, 30);
    await rec.run();
    final s = (await shifts()).single;
    expect(s['origin'], 'auto');
    expect(s['opened_at'], DateTime.utc(2026, 11, 16, 6).toIso8601String());
    // running again does nothing
    await rec.run();
    expect(await shifts(), hasLength(1));
  });

  test('before the window nothing opens', () async {
    f.clock = DateTime.utc(2026, 11, 16, 5, 0); // 07:00 local
    await rec.run();
    expect(await shifts(), isEmpty);
  });

  test('after the close time it closes at the scheduled time', () async {
    f.clock = DateTime.utc(2026, 11, 16, 7, 30);
    await rec.run();
    // 22:00 local = 20:00 UTC; now 20:10 UTC
    f.clock = DateTime.utc(2026, 11, 16, 20, 10);
    await rec.run();
    final s = (await shifts()).single;
    expect(s['closed_at'], DateTime.utc(2026, 11, 16, 20).toIso8601String());
    expect(s['counted_cash'], '0.00'); // drawer off: nothing to count
  });

  test('drawer on: the auto close waits for a count', () async {
    features = const BusinessFeatures(
      shiftsMode: ShiftsMode.auto,
      cashDrawerFlag: true,
    );
    f.clock = DateTime.utc(2026, 11, 16, 7, 30);
    await rec.run();
    f.clock = DateTime.utc(2026, 11, 16, 20, 10);
    await rec.run();
    final s = (await shifts()).single;
    expect(s['counted_cash'], isNull);
    expect(s['expected_cash'], '0.00');
  });

  test('an early manual close is not reopened in the same window', () async {
    f.clock = DateTime.utc(2026, 11, 16, 7, 30);
    await rec.run();
    f.clock = DateTime.utc(2026, 11, 16, 9, 0);
    await svc.close(origin: ShiftOrigin.auto);
    await rec.run();
    expect(await shifts(), hasLength(1));
  });

  test('manual or off mode does nothing', () async {
    features = const BusinessFeatures(shiftsMode: ShiftsMode.manual);
    f.clock = DateTime.utc(2026, 11, 16, 7, 30);
    await rec.run();
    expect(await shifts(), isEmpty);
  });

  test('uses the store it was given', () {
    expect(const ShiftStore(), isA<ShiftStore>());
  });
}
