import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:sqflite/sqflite.dart';

import '../data/shift_store.dart';
import 'shift.dart';
import 'shift_schedule.dart';
import 'shift_service.dart';

/// Applies the auto shift schedule: opens and closes the shift of the current
/// shop at the scheduled business-time moments. Called on app start, on
/// resume and every 30 s while the app is open (a phone cannot run a clock
/// while the app is closed, so a late open or close is stamped with the
/// scheduled time, like desktop). Never touches a sale. Idempotent.
class ShiftReconciler {
  ShiftReconciler({
    required ShiftService service,
    required Future<Database> Function() db,
    required BusinessFeatures Function() features,
    required String? Function() shopId,
    required Future<String?> Function() timezone,
    ShiftStore store = const ShiftStore(),
    DateTime Function()? now,
  }) : _service = service,
       _db = db,
       _features = features,
       _shopId = shopId,
       _timezone = timezone,
       _store = store,
       _now = now ?? DateTime.now;

  final ShiftService _service;
  final Future<Database> Function() _db;
  final BusinessFeatures Function() _features;
  final String? Function() _shopId;
  final Future<String?> Function() _timezone;
  final ShiftStore _store;
  final DateTime Function() _now;

  var _running = false;

  /// Returns true when it opened or closed a shift.
  Future<bool> run() async {
    if (_running) return false;
    final f = _features();
    final shop = _shopId();
    if (f.shiftsMode != ShiftsMode.auto || shop == null || shop.isEmpty) {
      return false;
    }
    _running = true;
    try {
      final offset = BusinessDay.offsetOf(await _timezone());
      DateTime local(DateTime utc) => utc.toUtc().add(offset);
      DateTime utcOf(DateTime local) => local.subtract(offset);

      final db = await _db();
      final open = await _store.open(db, shop);
      final latest = await _store.latest(db, shop);
      final action = ShiftSchedule.evaluate(
        local(_now()),
        mode: f.shiftsMode,
        autoOpen: f.shiftsAutoOpen,
        autoClose: f.shiftsAutoClose,
        openShiftOpenedAt: open == null ? null : local(open.openedAt),
        lastShiftOpenedAt: latest == null ? null : local(latest.openedAt),
      );
      switch (action) {
        case ScheduleNone():
          return false;
        case ScheduleOpen(:final at):
          final r = await _service.open(
            origin: ShiftOrigin.auto,
            at: utcOf(at),
          );
          return r is ShiftDone;
        case ScheduleClose(:final at):
          final r = await _service.close(
            origin: ShiftOrigin.auto,
            at: utcOf(at),
          );
          return r is ShiftDone;
      }
    } finally {
      _running = false;
    }
  }
}
