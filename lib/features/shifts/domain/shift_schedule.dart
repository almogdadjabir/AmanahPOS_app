import 'package:amana_pos/core/features/business_features.dart';

/// What the auto schedule wants done right now.
sealed class ScheduleAction {
  const ScheduleAction();
}

class ScheduleNone extends ScheduleAction {
  const ScheduleNone();
}

class ScheduleOpen extends ScheduleAction {
  const ScheduleOpen(this.at);

  /// Scheduled start of the window, in business time.
  final DateTime at;
}

class ScheduleClose extends ScheduleAction {
  const ScheduleClose(this.at);

  /// Scheduled close, in business time.
  final DateTime at;
}

/// Window maths for auto shifts (port of desktop `ShiftSchedule`). Every
/// DateTime here is BUSINESS time carried in a UTC-flagged value (the clock
/// fields are the business wall clock); callers convert at the edge.
abstract final class ShiftSchedule {
  static DateTime _at(DateTime day, ShiftTime t) =>
      DateTime.utc(day.year, day.month, day.day, t.hour, t.minute);

  /// The latest occurrence of [time] at or before [now].
  static DateTime lastAtOrBefore(DateTime now, ShiftTime time) {
    final today = _at(now, time);
    return today.isAfter(now) ? today.subtract(const Duration(days: 1)) : today;
  }

  /// The first occurrence of [time] strictly after [moment].
  static DateTime firstAfter(DateTime moment, ShiftTime time) {
    final today = _at(moment, time);
    return today.isAfter(moment) ? today : today.add(const Duration(days: 1));
  }

  /// One step of the auto schedule. [openShiftOpenedAt] is when the open
  /// shift started (null when none); [lastShiftOpenedAt] when the latest
  /// shift of any state started: a window that already had a shift, even one
  /// closed early, is not opened again.
  static ScheduleAction evaluate(
    DateTime now, {
    required ShiftsMode mode,
    required ShiftTime autoOpen,
    required ShiftTime autoClose,
    DateTime? openShiftOpenedAt,
    DateTime? lastShiftOpenedAt,
  }) {
    if (mode != ShiftsMode.auto || autoOpen == autoClose) {
      return const ScheduleNone();
    }
    final opened = openShiftOpenedAt;
    if (opened != null) {
      final due = firstAfter(opened, autoClose);
      return now.isBefore(due) ? const ScheduleNone() : ScheduleClose(due);
    }
    final start = lastAtOrBefore(now, autoOpen);
    final inWindow = now.isBefore(firstAfter(start, autoClose));
    final last = lastShiftOpenedAt;
    final already = last != null && !last.isBefore(start);
    return inWindow && !already ? ScheduleOpen(start) : const ScheduleNone();
  }
}
