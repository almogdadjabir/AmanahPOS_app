import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Custom range: From and To rows over a month calendar. Resolves with the
/// chosen range, or null when dismissed.
Future<DateTimeRange?> showReportRangeSheet(
  BuildContext context, {
  DateTimeRange? initial,
}) {
  return showAdaptivePanel<DateTimeRange>(
    context,
    showDragHandle: false,
    builder: (_) => _RangeSheet(initial: initial),
  );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class _RangeSheet extends StatefulWidget {
  final DateTimeRange? initial;
  const _RangeSheet({this.initial});

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late final DateTime _today = _day(DateTime.now());
  late DateTime _from;
  late DateTime _to;
  late DateTime _month;
  bool _editingTo = true;

  @override
  void initState() {
    super.initState();
    _from = _day(
      widget.initial?.start ?? DateTime(_today.year, _today.month, 1),
    );
    _to = _day(widget.initial?.end ?? _today);
    _month = DateTime(_to.year, _to.month);
  }

  void _pick(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_editingTo) {
        if (d.isBefore(_from)) {
          _from = d;
        } else {
          _to = d;
        }
      } else {
        _from = d;
        if (_to.isBefore(d)) _to = d;
        _editingTo = true;
      }
    });
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(locale);

    return AppSheet(
      title: tr.rpCustomRange,
      maxHeightFactor: 0.92,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailingAction: AppSheetAction(
        label: tr.rpApply,
        emphasized: true,
        onTap: () =>
            Navigator.of(context).pop(DateTimeRange(start: _from, end: _to)),
      ),
      child: Column(
        children: [
          _Card(
            child: Column(
              children: [
                _RangeRow(
                  label: tr.rpFrom,
                  value: fmt.format(_from),
                  active: !_editingTo,
                  onTap: () => setState(() => _editingTo = false),
                ),
                _RangeRow(
                  label: tr.rpTo,
                  value: fmt.format(_to),
                  active: _editingTo,
                  divider: true,
                  onTap: () => setState(() => _editingTo = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              child: Column(
                children: [
                  _MonthHeader(
                    title: DateFormat.yMMMM(locale).format(_month),
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                  ),
                  _Grid(
                    month: _month,
                    from: _from,
                    to: _to,
                    today: _today,
                    locale: locale,
                    onPick: _pick,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // The sheet itself is the surface colour, so the cards go one step
        // back to the page colour to stay visible (HTML: bg sheet, surface card).
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final bool divider;
  final VoidCallback onTap;

  const _RangeRow({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Pressable(
      onTap: onTap,
      scale: 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: divider
              ? Border(top: BorderSide(color: colors.border, width: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 17, color: colors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: active
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: active ? colors.primaryContainer : null,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Pressable(
                  onTap: onPrev,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      PhosphorIconsRegular.caretLeft,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Pressable(
                  onTap: onNext,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-column month grid, Sunday first, always left to right.
class _Grid extends StatelessWidget {
  final DateTime month;
  final DateTime from;
  final DateTime to;
  final DateTime today;
  final String locale;
  final ValueChanged<DateTime> onPick;

  const _Grid({
    required this.month,
    required this.from,
    required this.to,
    required this.today,
    required this.locale,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final first = DateTime(month.year, month.month);
    final lead = first.weekday % 7; // Sunday = 0
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <Widget>[];

    // 2023-01-01 is a Sunday.
    final narrow = DateFormat.EEEEE(locale);
    for (var i = 0; i < 7; i++) {
      cells.add(
        SizedBox(
          height: 24,
          child: Center(
            child: Text(
              narrow.format(DateTime(2023, 1, 1 + i)),
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox(height: 38));
    }
    for (var d = 1; d <= count; d++) {
      final date = DateTime(month.year, month.month, d);
      final isEnd = date == from || date == to;
      final inRange = date.isAfter(from) && date.isBefore(to);
      final future = date.isAfter(today);

      Color? bg;
      Color fg = colors.textPrimary;
      var weight = FontWeight.w400;
      var shape = BoxShape.rectangle;
      if (isEnd) {
        bg = colors.primary;
        fg = colors.onPrimary;
        weight = FontWeight.w600;
        shape = BoxShape.circle;
      } else if (inRange) {
        bg = colors.primaryContainer;
        fg = colors.primary;
      } else if (future) {
        fg = colors.disabled;
      }

      cells.add(
        Pressable(
          onTap: future ? null : () => onPick(date),
          scale: 1,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: shape),
            child: Text(
              '$d',
              style: TextStyle(fontSize: 17, fontWeight: weight, color: fg),
            ),
          ),
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(const SizedBox(height: 38));
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: Row(
            children: [
              for (final c in cells.sublist(i, i + 7)) Expanded(child: c),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: rows),
    );
  }
}
