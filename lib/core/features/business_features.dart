import 'dart:async';
import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';

/// How the owner wants shifts to work (dashboard: `shifts_mode`).
enum ShiftsMode {
  off,
  auto,
  manual;

  static ShiftsMode parse(Object? v) => switch (v) {
    'auto' => ShiftsMode.auto,
    'manual' => ShiftsMode.manual,
    _ => ShiftsMode.off,
  };
}

/// What the owner switched on for this business, read from the business row
/// that sync already stores. A switch the server does not send yet takes the
/// default listed in `docs/BE_GAPS_PARITY.md` G1, so the till keeps working
/// against today's backend. Screens ask this and never read raw columns.
class BusinessFeatures {
  const BusinessFeatures({
    this.splitPayments = true,
    this.onAccount = true,
    this.lineDiscount = true,
    this.saleDiscount = true,
    this.stockCount = true,
    this.shiftsMode = ShiftsMode.off,
    this.shiftsAutoOpen = false,
    this.shiftsAutoClose = false,
    this.cashiersMayOperateShifts = false,
    bool cashDrawerFlag = false,
  }) : _cashDrawerFlag = cashDrawerFlag;

  final bool splitPayments;
  final bool onAccount;
  final bool lineDiscount;
  final bool saleDiscount;
  final bool stockCount;
  final ShiftsMode shiftsMode;
  final bool shiftsAutoOpen;
  final bool shiftsAutoClose;
  final bool cashiersMayOperateShifts;
  final bool _cashDrawerFlag;

  bool get shiftsEnabled => shiftsMode != ShiftsMode.off;

  /// Pay-in, pay-out and expected cash only exist inside a shift.
  bool get cashDrawer => _cashDrawerFlag && shiftsEnabled;

  factory BusinessFeatures.fromJson(Map<String, dynamic> j) {
    bool on(String key, bool fallback) {
      final v = j[key];
      return v is bool ? v : fallback;
    }

    return BusinessFeatures(
      splitPayments: on('split_payments_enabled', true),
      onAccount: on('on_account_enabled', true),
      lineDiscount: on('line_discount_enabled', true),
      saleDiscount: on('sale_discount_enabled', true),
      stockCount: on('stock_count_enabled', true),
      shiftsMode: ShiftsMode.parse(j['shifts_mode']),
      shiftsAutoOpen: on('shifts_auto_open', false),
      shiftsAutoClose: on('shifts_auto_close', false),
      cashiersMayOperateShifts: on('shifts_cashiers_may_operate', false),
      cashDrawerFlag: on('cash_drawer_enabled', false),
    );
  }
}

/// Keeps the current [BusinessFeatures] in memory and re-reads it when the
/// business row changes. Offline-first: nothing here touches the network.
class BusinessFeaturesService {
  BusinessFeaturesService({
    required OfflineDb db,
    required DbChangeNotifier notifier,
  }) : _db = db,
       _notifier = notifier;

  final OfflineDb _db;
  final DbChangeNotifier _notifier;
  final _out = StreamController<BusinessFeatures>.broadcast();
  StreamSubscription<Set<String>>? _sub;
  var _current = const BusinessFeatures();
  var _generation = 0;

  /// The last value read, or the defaults before the first [load].
  BusinessFeatures get current => _current;

  /// Emits the new value whenever the stored business row changes.
  Stream<BusinessFeatures> get changes => _out.stream;

  /// Reads the stored row, remembers it and starts listening for changes.
  Future<BusinessFeatures> load() async {
    _sub ??= _notifier.changes.listen((tables) {
      if (tables.contains('synced_entities') || tables.contains('businesses')) {
        unawaited(_refresh());
      }
    });
    return _read();
  }

  Future<void> _refresh() async {
    final before = _current;
    final next = await _read();
    if (!_same(before, next) && !_out.isClosed) _out.add(next);
  }

  Future<BusinessFeatures> _read() async {
    final gen = ++_generation;
    final db = await _db.database;
    var row = await _json(
      db.query(
        'synced_entities',
        columns: ['json'],
        where: 'entity = ?',
        whereArgs: ['business'],
        limit: 1,
      ),
    );
    if (row.isEmpty) {
      row = await _json(db.query('businesses', columns: ['json'], limit: 1));
    }
    final value = BusinessFeatures.fromJson(row);
    // A slower, older read must not overwrite a newer one.
    if (gen == _generation) _current = value;
    return value;
  }

  Future<Map<String, dynamic>> _json(
    Future<List<Map<String, Object?>>> rows,
  ) async {
    final r = await rows;
    if (r.isEmpty) return const {};
    try {
      final d = jsonDecode(r.first['json'] as String);
      return d is Map<String, dynamic> ? d : const {};
    } catch (_) {
      return const {};
    }
  }

  bool _same(BusinessFeatures a, BusinessFeatures b) =>
      a.splitPayments == b.splitPayments &&
      a.onAccount == b.onAccount &&
      a.lineDiscount == b.lineDiscount &&
      a.saleDiscount == b.saleDiscount &&
      a.stockCount == b.stockCount &&
      a.shiftsMode == b.shiftsMode &&
      a.shiftsAutoOpen == b.shiftsAutoOpen &&
      a.shiftsAutoClose == b.shiftsAutoClose &&
      a.cashiersMayOperateShifts == b.cashiersMayOperateShifts &&
      a.cashDrawer == b.cashDrawer;

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _out.close();
  }
}
