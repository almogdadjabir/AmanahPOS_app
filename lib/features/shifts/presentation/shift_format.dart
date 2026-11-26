import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_format.dart';
import 'package:amana_pos/l10n/app_localizations.dart';

import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/widgets.dart';

import '../domain/shift_service.dart';

/// `1,285.00`, `-5.00`. Cents in, display text out (Latin digits).
String shiftMoney(BigInt cents) => receiptAmount(cents.toDouble() / 100);

String _two(int n) => n.toString().padLeft(2, '0');

/// `08:00` in business time.
String shiftClock(DateTime utc, Duration offset) {
  final l = utc.toUtc().add(offset);
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// `26/11` in business time.
String shiftDay(DateTime utc, Duration offset) {
  final l = utc.toUtc().add(offset);
  return '${_two(l.day)}/${_two(l.month)}';
}

/// `26/11 08:00 – 22:05` (or `26/11 08:00` while open).
String shiftSpan(DateTime opened, DateTime? closed, Duration offset) {
  final from = '${shiftDay(opened, offset)} ${shiftClock(opened, offset)}';
  if (closed == null) return from;
  final sameDay = shiftDay(opened, offset) == shiftDay(closed, offset);
  final to = sameDay
      ? shiftClock(closed, offset)
      : '${shiftDay(closed, offset)} ${shiftClock(closed, offset)}';
  return '$from – $to';
}

/// Digits typed with Arabic-Indic numerals become Latin; a comma decimal
/// separator becomes a dot.
String normalizeAmountInput(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final r in raw.runes) {
    final c = String.fromCharCode(r);
    final a = arabic.indexOf(c);
    final p = persian.indexOf(c);
    if (a >= 0) {
      b.write(a);
    } else if (p >= 0) {
      b.write(p);
    } else if (c == '٫' || c == ',') {
      b.write('.');
    } else {
      b.write(c);
    }
  }
  return b.toString().trim();
}

String shiftErrorText(AppLocalizations tr, ShiftError e) => switch (e) {
  ShiftError.noSession => tr.sfErrNoSession,
  ShiftError.noShop => tr.sfErrNoShop,
  ShiftError.disabled => tr.sfErrDisabled,
  ShiftError.drawerOff => tr.sfErrDrawerOff,
  ShiftError.notAllowed => tr.sfErrNotAllowed,
  ShiftError.alreadyOpen => tr.sfErrAlreadyOpen,
  ShiftError.notOpen => tr.sfErrNotOpen,
  ShiftError.notFound => tr.sfErrNotFound,
  ShiftError.notCountable => tr.sfErrNotCountable,
  ShiftError.amountInvalid => tr.sfErrAmount,
  ShiftError.reasonRequired => tr.sfErrReason,
};

/// Toast for the outcome of a write: [done] on success, the reason on failure.
void shiftToast(BuildContext context, ShiftResult result, String done) {
  switch (result) {
    case ShiftDone():
      GlobalSnackBar.showSuccess(message: done);
    case ShiftFailed(:final error):
      GlobalSnackBar.showError(message: shiftErrorText(context.tr, error));
  }
}
