import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Number and text formats of the receipt. They match the desktop
/// `ReceiptVisual` exactly: Latin digits, `#,##0.00` amounts, `#,##0.###`
/// quantities, English month names in both languages.
final NumberFormat _amount = NumberFormat('#,##0.00', 'en');
final NumberFormat _qty = NumberFormat('#,##0.###', 'en');

String receiptAmount(double v) => _amount.format(v);

String receiptQty(double v) => _qty.format(v);

/// `26 Nov 2026 · 14:05` in the business time zone.
String receiptWhen(DateTime instant, String? timezone) {
  final local = instant.toUtc().add(BusinessDay.offsetOf(timezone));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)} ${_months[local.month - 1]} ${local.year} · '
      '${two(local.hour)}:${two(local.minute)}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Left-to-right isolate so digits keep their order inside Arabic text.
String isolateLtr(String s) => '\u2066$s\u2069';

/// The tax row label from the tax stored with the sale: `Tax (VAT 15%)` when
/// added on top, `Incl. VAT 15%` when already in the prices, `Tax` when the
/// sale has no rate.
String receiptTaxLabel(ReceiptDoc doc, AppLocalizations l) {
  if (doc.taxRate <= 0) return l.rcTax;
  final rate = isolateLtr(NumberFormat('0.##', 'en').format(doc.taxRate));
  final name = doc.taxName.trim();
  if (doc.taxInclusive) {
    return name.isNotEmpty
        ? l.rcTaxInclNamed(name, rate)
        : l.rcTaxInclRated(rate);
  }
  return name.isNotEmpty ? l.rcTaxNamed(name, rate) : l.rcTaxRated(rate);
}

String receiptMethod(AppLocalizations l, String method) => switch (method) {
  'cash' => l.rcPayCash,
  'bankak' => l.rcPayBankak,
  'card' => l.rcPayCard,
  'split' => l.rcPaySplit,
  'credit' => l.rcPayCredit,
  _ => method,
};

String receiptStatus(AppLocalizations l, String status) => switch (status) {
  'completed' => l.rcStatusCompleted,
  'partial_refund' => l.rcStatusPartialRefund,
  'refunded' => l.rcStatusRefunded,
  'cancelled' => l.rcStatusCancelled,
  'pending' => l.rcStatusPending,
  'failed' => l.rcStatusFailed,
  _ => status,
};
