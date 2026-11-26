import 'package:amana_pos/core/features/business_features.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../../../core/sync/sync_state_store.dart';
import '../data/shift_store.dart';
import 'cash_expectation.dart';
import 'shift.dart';

/// Who is acting. [canManage] is owner or manager.
class ShiftActor {
  const ShiftActor({
    required this.id,
    required this.name,
    required this.canManage,
  });

  final String id;
  final String name;
  final bool canManage;
}

enum ShiftError {
  noSession,
  noShop,
  disabled,
  drawerOff,
  notAllowed,
  alreadyOpen,
  notOpen,
  notFound,
  notCountable,
  amountInvalid,
  reasonRequired,
}

sealed class ShiftResult {
  const ShiftResult();
}

class ShiftDone extends ShiftResult {
  const ShiftDone({this.expected, this.difference, this.exceedsDrawer = false});

  /// Cash the drawer should hold (after a close, count or movement).
  final BigInt? expected;

  /// Counted minus expected, when a count was entered.
  final BigInt? difference;

  /// A pay-out larger than the drawer cash: allowed, flagged.
  final bool exceedsDrawer;
}

class ShiftFailed extends ShiftResult {
  const ShiftFailed(this.error);
  final ShiftError error;
}

/// Order on the wire is the outbox sequence: a shift's open is always queued
/// before its close, count and movements. (The outbox only tracks `create`
/// dependencies, so none are declared.)
///
/// The only writer of shifts and cash movements. Each call is ONE
/// [LocalWriter.write]: the local row and its outbox row commit together.
/// A shift never touches a sale, so it can never delay or block a checkout.
class ShiftService {
  ShiftService({
    required LocalWriter writer,
    required SyncStateStore state,
    required BusinessFeatures Function() features,
    required ShiftActor? Function() actor,
    required String? Function() shopId,
    ShiftStore store = const ShiftStore(),
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _state = state,
       _features = features,
       _actor = actor,
       _shopId = shopId,
       _store = store,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final SyncStateStore _state;
  final BusinessFeatures Function() _features;
  final ShiftActor? Function() _actor;
  final String? Function() _shopId;
  final ShiftStore _store;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const Set<String> tables = {'shifts', 'cash_movements', SyncTables.outbox};

  String _money(BigInt cents) => Cents.format(cents);

  /// Common gate for open, close and count. Null means allowed.
  ShiftError? _gate({required bool manage, required ShiftOrigin origin}) {
    final f = _features();
    if (!f.shiftsEnabled) return ShiftError.disabled;
    if (origin == ShiftOrigin.auto) return null; // the schedule, no person
    final a = _actor();
    if (a == null) return ShiftError.noSession;
    if (manage && !a.canManage && !f.cashiersMayOperateShifts) {
      return ShiftError.notAllowed;
    }
    return null;
  }

  Future<ShiftResult> open({
    BigInt? openingCash,
    ShiftOrigin origin = ShiftOrigin.manual,
    DateTime? at,
    String? note,
  }) async {
    final gate = _gate(manage: true, origin: origin);
    if (gate != null) return ShiftFailed(gate);
    final shop = _shopId();
    if (shop == null || shop.isEmpty) return const ShiftFailed(ShiftError.noShop);
    if (openingCash != null && openingCash.isNegative) {
      return const ShiftFailed(ShiftError.amountInvalid);
    }
    final f = _features();
    final actor = origin == ShiftOrigin.auto ? null : _actor();
    final deviceId = await _state.deviceId();
    final openedAt = (at ?? _now()).toUtc();
    final id = _uuid.v4();

    return _writer.write<ShiftResult>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        if (await _store.open(txn, shop) != null) {
          return const ShiftFailed(ShiftError.alreadyOpen);
        }
        final opening = !f.cashDrawer
            ? BigInt.zero
            : openingCash ??
                  await _store.carryOverCash(txn, shop) ??
                  BigInt.zero;
        await txn.insert('shifts', {
          'id': id,
          'shop_id': shop,
          'opened_at': openedAt.toIso8601String(),
          'opened_by': actor?.id,
          'opened_by_name': actor?.name,
          'opening_cash': _money(opening),
          'origin': origin.name,
          'note': note,
          'sync_state': 'pending',
        });
        await scope.enqueue(
          entity: 'shift',
          op: 'open',
          entityId: id,
          occurredAt: openedAt,
          payload: {
            'shop_id': shop,
            'opened_at': openedAt.toIso8601String(),
            if (actor != null) 'opened_by': actor.id,
            'opening_cash': _money(opening),
            'origin': origin.name,
            'device_id': deviceId,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
        return const ShiftDone();
      },
    );
  }

  /// Closes the open shift of the current shop. [counted] is the cash count
  /// (null for an automatic close: the shift then waits for a count).
  Future<ShiftResult> close({
    BigInt? counted,
    String? note,
    ShiftOrigin origin = ShiftOrigin.manual,
    DateTime? at,
  }) async {
    final gate = _gate(manage: true, origin: origin);
    if (gate != null) return ShiftFailed(gate);
    final shop = _shopId();
    if (shop == null || shop.isEmpty) return const ShiftFailed(ShiftError.noShop);
    if (counted != null && counted.isNegative) {
      return const ShiftFailed(ShiftError.amountInvalid);
    }
    final drawer = _features().cashDrawer;
    final actor = origin == ShiftOrigin.auto ? null : _actor();
    final closedAt = (at ?? _now()).toUtc();

    return _writer.write<ShiftResult>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final shift = await _store.open(txn, shop);
        if (shift == null) return const ShiftFailed(ShiftError.notOpen);
        // Without the drawer a shift has no cash: it closes as counted zero,
        // so it never waits for a count.
        final expected = drawer
            ? (await _store.figures(
                txn,
                ShiftInfo(
                  id: shift.id,
                  shopId: shift.shopId,
                  openedAt: shift.openedAt,
                  openedByName: shift.openedByName,
                  origin: shift.origin,
                  openingCash: shift.openingCash,
                  closedAt: closedAt,
                ),
              )).expected
            : BigInt.zero;
        final finalCounted = drawer ? counted : BigInt.zero;
        await txn.update(
          'shifts',
          {
            'closed_at': closedAt.toIso8601String(),
            'closed_by': actor?.id,
            'closed_by_name': actor?.name,
            'expected_cash': _money(expected),
            'counted_cash': finalCounted == null ? null : _money(finalCounted),
            if (note != null && note.isNotEmpty) 'note': note,
          },
          where: 'id = ?',
          whereArgs: [shift.id],
        );
        await scope.enqueue(
          entity: 'shift',
          op: 'close',
          entityId: shift.id,
          occurredAt: closedAt,
          payload: {
            'expected_cash': _money(expected),
            if (finalCounted != null) 'counted_cash': _money(finalCounted),
            'closed_at': closedAt.toIso8601String(),
            if (actor != null) 'closed_by': actor.id,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
        return ShiftDone(
          expected: expected,
          difference: finalCounted == null
              ? null
              : CashExpectation.difference(finalCounted, expected),
        );
      },
    );
  }

  /// Enters the count of a closed shift that has none.
  Future<ShiftResult> count(
    String shiftId,
    BigInt counted, {
    String? note,
  }) async {
    final gate = _gate(manage: true, origin: ShiftOrigin.manual);
    if (gate != null) return ShiftFailed(gate);
    if (!_features().cashDrawer) return const ShiftFailed(ShiftError.drawerOff);
    if (counted.isNegative) return const ShiftFailed(ShiftError.amountInvalid);

    return _writer.write<ShiftResult>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final shift = await _store.byId(txn, shiftId);
        if (shift == null) return const ShiftFailed(ShiftError.notFound);
        if (shift.state != ShiftState.needsCount) {
          return const ShiftFailed(ShiftError.notCountable);
        }
        final expected = shift.expected ?? BigInt.zero;
        await txn.update(
          'shifts',
          {
            'counted_cash': _money(counted),
            if (note != null && note.isNotEmpty) 'note': note,
          },
          where: 'id = ?',
          whereArgs: [shiftId],
        );
        await scope.enqueue(
          entity: 'shift',
          op: 'count',
          entityId: shiftId,
          occurredAt: _now().toUtc(),
          payload: {
            'counted_cash': _money(counted),
            'expected_cash': _money(expected),
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
        return ShiftDone(
          expected: expected,
          difference: CashExpectation.difference(counted, expected),
        );
      },
    );
  }

  /// A pay-in or pay-out in the open shift. Any signed-in user may do it.
  Future<ShiftResult> addMovement({
    required bool isPayIn,
    required BigInt amount,
    required String reason,
  }) async {
    final f = _features();
    if (!f.shiftsEnabled) return const ShiftFailed(ShiftError.disabled);
    if (!f.cashDrawer) return const ShiftFailed(ShiftError.drawerOff);
    final actor = _actor();
    if (actor == null) return const ShiftFailed(ShiftError.noSession);
    final shop = _shopId();
    if (shop == null || shop.isEmpty) return const ShiftFailed(ShiftError.noShop);
    if (amount <= BigInt.zero) return const ShiftFailed(ShiftError.amountInvalid);
    final why = reason.trim();
    if (why.isEmpty) return const ShiftFailed(ShiftError.reasonRequired);
    final at = _now().toUtc();
    final id = _uuid.v4();

    return _writer.write<ShiftResult>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final shift = await _store.open(txn, shop);
        if (shift == null) return const ShiftFailed(ShiftError.notOpen);
        final before = (await _store.figures(txn, shift, now: at)).expected;
        final kind = isPayIn ? 'pay_in' : 'pay_out';
        await txn.insert('cash_movements', {
          'id': id,
          'shift_id': shift.id,
          'kind': kind,
          'amount': _money(amount),
          'reason': why,
          'occurred_at': at.toIso8601String(),
          'user_id': actor.id,
          'user_name': actor.name,
          'sync_state': 'pending',
        });
        await scope.enqueue(
          entity: 'cash_movement',
          op: 'create',
          entityId: id,
          occurredAt: at,
          payload: {
            'shift_id': shift.id,
            'kind': kind,
            'amount': _money(amount),
            'reason': why,
            'occurred_at': at.toIso8601String(),
          },
        );
        return ShiftDone(
          expected: isPayIn ? before + amount : before - amount,
          exceedsDrawer: !isPayIn && CashExpectation.payOutExceeds(before, amount),
        );
      },
    );
  }
}
