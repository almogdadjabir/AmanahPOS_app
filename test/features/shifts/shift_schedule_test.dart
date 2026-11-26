import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/domain/shift_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

const open8 = ShiftTime(8, 0);
const close22 = ShiftTime(22, 0);

DateTime t(int d, int h, [int m = 0]) => DateTime.utc(2026, 1, d, h, m);

ScheduleAction eval(
  DateTime now, {
  ShiftTime open = open8,
  ShiftTime close = close22,
  DateTime? openShift,
  DateTime? lastShift,
  ShiftsMode mode = ShiftsMode.auto,
}) => ShiftSchedule.evaluate(
  now,
  mode: mode,
  autoOpen: open,
  autoClose: close,
  openShiftOpenedAt: openShift,
  lastShiftOpenedAt: lastShift,
);

void main() {
  test('inside the window with no shift: open at the window start', () {
    final a = eval(t(5, 9));
    expect(a, isA<ScheduleOpen>());
    expect((a as ScheduleOpen).at, t(5, 8));
  });

  test('before the window: nothing', () {
    expect(eval(t(5, 7, 59)), isA<ScheduleNone>());
  });

  test('after the window with no open shift: nothing', () {
    expect(eval(t(5, 22, 30)), isA<ScheduleNone>());
  });

  test('a window that already had a shift is not opened again', () {
    expect(eval(t(5, 12), lastShift: t(5, 8, 5)), isA<ScheduleNone>());
  });

  test('yesterday window shift does not block today', () {
    expect(eval(t(5, 9), lastShift: t(4, 8)), isA<ScheduleOpen>());
  });

  test('open shift is closed at the first close time after it opened', () {
    final a = eval(t(5, 22, 1), openShift: t(5, 8));
    expect(a, isA<ScheduleClose>());
    expect((a as ScheduleClose).at, t(5, 22));
  });

  test('open shift before its close time: nothing', () {
    expect(eval(t(5, 21, 59), openShift: t(5, 8)), isA<ScheduleNone>());
  });

  test('a shift left open overnight is closed at its own close time', () {
    final a = eval(t(6, 9), openShift: t(5, 8));
    expect((a as ScheduleClose).at, t(5, 22));
  });

  test('close earlier than open crosses midnight', () {
    // 22:00 -> 06:00
    final a = eval(
      t(6, 1),
      open: const ShiftTime(22, 0),
      close: const ShiftTime(6, 0),
    );
    expect(a, isA<ScheduleOpen>());
    expect((a as ScheduleOpen).at, t(5, 22));
    final c = eval(
      t(6, 6, 1),
      open: const ShiftTime(22, 0),
      close: const ShiftTime(6, 0),
      openShift: t(5, 22),
    );
    expect((c as ScheduleClose).at, t(6, 6));
  });

  test('not auto, or equal times: nothing', () {
    expect(eval(t(5, 9), mode: ShiftsMode.manual), isA<ScheduleNone>());
    expect(eval(t(5, 9), mode: ShiftsMode.off), isA<ScheduleNone>());
    expect(
      eval(t(5, 9), open: open8, close: open8),
      isA<ScheduleNone>(),
    );
  });
}
