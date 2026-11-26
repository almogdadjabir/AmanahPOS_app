import 'dart:async';

import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/shift_store.dart';
import '../domain/shift.dart';
import '../domain/shift_reconciler.dart';
import '../domain/shift_service.dart';

class ShiftsState {
  const ShiftsState({
    this.loading = true,
    this.failed = false,
    this.features = const BusinessFeatures(),
    this.open,
    this.figures,
    this.movements = const [],
    this.history = const [],
    this.hasMore = false,
    this.needsCount = 0,
  });

  final bool loading;
  final bool failed;
  final BusinessFeatures features;
  final ShiftInfo? open;

  /// Figures of the open shift (null when none).
  final ShiftFigures? figures;
  final List<CashMovementInfo> movements;

  /// Closed shifts, newest first.
  final List<ShiftInfo> history;
  final bool hasMore;
  final int needsCount;

  Duration get offset => BusinessDay.offsetOf(features.timezone);

  ShiftsState copyWith({
    bool? loading,
    bool? failed,
    BusinessFeatures? features,
    ShiftInfo? open,
    bool clearOpen = false,
    ShiftFigures? figures,
    List<CashMovementInfo>? movements,
    List<ShiftInfo>? history,
    bool? hasMore,
    int? needsCount,
  }) => ShiftsState(
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    features: features ?? this.features,
    open: clearOpen ? null : (open ?? this.open),
    figures: clearOpen ? null : (figures ?? this.figures),
    movements: clearOpen ? const [] : (movements ?? this.movements),
    history: history ?? this.history,
    hasMore: hasMore ?? this.hasMore,
    needsCount: needsCount ?? this.needsCount,
  );
}

/// Reads shifts for the selected shop and reacts to local changes. Also
/// drives the auto schedule (see [ShiftReconciler]) when [startSchedule] is
/// called. Writes go through [ShiftService].
class ShiftsCubit extends Cubit<ShiftsState> {
  ShiftsCubit({
    required ShiftService service,
    required ShiftReconciler reconciler,
    required BusinessFeaturesService features,
    required OfflineDb db,
    required DbChangeNotifier notifier,
    required String? Function() shopId,
    ShiftStore store = const ShiftStore(),
    DateTime Function()? now,
  }) : _service = service,
       _reconciler = reconciler,
       _featuresService = features,
       _db = db,
       _store = store,
       _shopId = shopId,
       _now = now ?? DateTime.now,
       super(const ShiftsState()) {
    _tables = notifier.changes.listen((t) {
      if (t.any(_watched.contains)) _schedule();
    });
    _features = features.changes.listen((_) => _schedule());
  }

  static const _watched = {
    'shifts',
    'cash_movements',
    'sales',
    'sale_payments',
    'sale_refunds',
    'synced_entities',
    'businesses',
  };
  static const _pageSize = 20;

  final ShiftService _service;
  final ShiftReconciler _reconciler;
  final BusinessFeaturesService _featuresService;
  final OfflineDb _db;
  final ShiftStore _store;
  final String? Function() _shopId;
  final DateTime Function() _now;
  late final StreamSubscription<Set<String>> _tables;
  late final StreamSubscription<BusinessFeatures> _features;
  Timer? _debounce;
  Timer? _ticker;
  var _gen = 0;

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), load);
  }

  /// Reads everything again for the selected shop.
  Future<void> load() async {
    final gen = ++_gen;
    try {
      final features = await _featuresService.load();
      final shop = _shopId();
      final db = await _db.database;
      if (!features.shiftsEnabled || shop == null || shop.isEmpty) {
        if (gen != _gen || isClosed) return;
        emit(
          ShiftsState(loading: false, features: features),
        );
        return;
      }
      final open = await _store.open(db, shop);
      final figures = open == null
          ? null
          : await _store.figures(db, open, now: _now());
      final movements = open == null
          ? const <CashMovementInfo>[]
          : await _store.movements(db, open.id);
      final all = await _store.list(db, shop, limit: _pageSize + 1);
      final closed = [
        for (final s in all)
          if (!s.isOpen) s,
      ];
      final needs = await _store.countNeedingCount(db, shop);
      if (gen != _gen || isClosed) return;
      emit(
        ShiftsState(
          loading: false,
          features: features,
          open: open,
          figures: figures,
          movements: movements,
          history: closed.length > _pageSize
              ? closed.sublist(0, _pageSize)
              : closed,
          hasMore: all.length > _pageSize,
          needsCount: needs,
        ),
      );
    } catch (e, st) {
      debugPrint('Shifts load failed: $e\n$st');
      if (gen != _gen || isClosed) return;
      emit(state.copyWith(loading: false, failed: true));
    }
  }

  Future<void> loadMore() async {
    final shop = _shopId();
    if (shop == null || state.history.isEmpty || !state.hasMore) return;
    final db = await _db.database;
    final more = await _store.list(
      db,
      shop,
      limit: _pageSize + 1,
      beforeOpenedAt: state.history.last.openedAt,
    );
    if (isClosed) return;
    final closed = [
      for (final s in more)
        if (!s.isOpen) s,
    ];
    emit(
      state.copyWith(
        history: [
          ...state.history,
          ...closed.length > _pageSize ? closed.sublist(0, _pageSize) : closed,
        ],
        hasMore: more.length > _pageSize,
      ),
    );
  }

  /// Figures and movements of a past shift (for its detail sheet).
  Future<(ShiftFigures, List<CashMovementInfo>)> detail(ShiftInfo s) async {
    final db = await _db.database;
    return (
      await _store.figures(db, s, now: _now()),
      await _store.movements(db, s.id),
    );
  }

  /// Applies the auto schedule once; true when it opened or closed a shift.
  Future<bool> tick() async {
    try {
      await _featuresService.load();
      final changed = await _reconciler.run();
      if (changed) await load();
      return changed;
    } catch (e, st) {
      debugPrint('Shift schedule failed: $e\n$st');
      return false;
    }
  }

  /// Runs [tick] now and every 30 s until the cubit closes.
  void startSchedule() {
    if (_ticker != null) return;
    unawaited(tick());
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => tick());
  }

  Future<ShiftResult> openShift({BigInt? openingCash}) =>
      _service.open(openingCash: openingCash);

  Future<ShiftResult> closeShift({BigInt? counted, String? note}) =>
      _service.close(counted: counted, note: note);

  Future<ShiftResult> countShift(String id, BigInt counted, {String? note}) =>
      _service.count(id, counted, note: note);

  Future<ShiftResult> move({
    required bool isPayIn,
    required BigInt amount,
    required String reason,
  }) => _service.addMovement(isPayIn: isPayIn, amount: amount, reason: reason);

  /// What the next shift would start with (the sheet's pre-filled amount).
  Future<BigInt?> carryOver() async {
    final shop = _shopId();
    if (shop == null) return null;
    return _store.carryOverCash(await _db.database, shop);
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _ticker?.cancel();
    await _tables.cancel();
    await _features.cancel();
    return super.close();
  }
}
