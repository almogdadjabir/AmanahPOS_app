import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared by the sales list, sale detail, return and reports screens.

/// "26,400" (no unit). Fractions only when there is one.
String saleNumber(num value) {
  final f = value % 1 == 0
      ? NumberFormat.decimalPattern('en_US')
      : (NumberFormat.decimalPattern('en_US')..maximumFractionDigits = 2);
  return f.format(value);
}

/// "26,400 SDG" / "26,400 ج.س".
String saleMoney(BuildContext context, num value) =>
    '${saleNumber(value)} ${context.tr.shUnit}';

/// Quantity text: 3, 2.5, 0.125.
String saleQty(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  var s = value.toStringAsFixed(3);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
}

/// HH:mm in the device's local time.
String saleTime(DateTime date) =>
    DateFormat('HH:mm', 'en_US').format(date.toLocal());

/// Today / Yesterday / weekday (within a week) / d MMM yyyy.
String saleDayLabel(BuildContext context, DateTime date) {
  final tr = context.tr;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return tr.shDateToday;
  if (diff == 1) return tr.shDateYesterday;
  if (diff > 1 && diff < 7) return DateFormat.EEEE(locale).format(local);
  return DateFormat.yMMMd(locale).format(local);
}

/// "Today · 09:41".
String saleWhen(BuildContext context, DateTime date) =>
    context.tr.shWhen(saleDayLabel(context, date), saleTime(date));

String salePaymentName(BuildContext context, String method) {
  final tr = context.tr;
  return switch (method) {
    'cash' => tr.shPayCash,
    'bankak' => tr.shPayBankak,
    'card' => tr.shPayCard,
    'bank_transfer' => tr.bankTransfer,
    'mobile_wallet' => tr.wallet,
    'split' => tr.spOption,
    'credit' => tr.dtOnAccount,
    _ => method,
  };
}

/// Rows and the detail hero: cash amber, Bankak indigo, everything else soft.
class SalePaymentTile extends StatelessWidget {
  final String method;
  final double size;
  final bool dimmed;

  const SalePaymentTile({
    super.key,
    required this.method,
    this.size = 44,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final (tint, icon) = switch (method) {
      'cash' => (AppTint.cash, PhosphorIconsRegular.money),
      'bankak' => (AppTint.digital, PhosphorIconsRegular.deviceMobile),
      _ => (AppTint.neutral, PhosphorIconsRegular.creditCard),
    };
    final colors = context.appColors;
    final (bg, fg) = switch (tint) {
      AppTint.cash => (colors.cashTint, colors.cashInk),
      AppTint.digital => (colors.digitalTint, colors.digitalInk),
      _ => (colors.surfaceSoft, colors.textSecondary),
    };
    // HTML: 12 radius on rows (44), 16 on the detail hero (56).
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 56 ? 16 : 12),
      ),
      child: Icon(icon, size: size >= 56 ? 26 : 22, color: fg),
    );
    return dimmed ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}

enum SalePillKind { neutral, bad, ok }

/// Small status pill. [SaleStatusPill.forSale] returns null for a normal
/// completed sale (rows stay quiet; the detail hero uses [completed]).
class SaleStatusPill extends StatelessWidget {
  final String label;
  final SalePillKind kind;
  final IconData? icon;

  const SaleStatusPill({
    super.key,
    required this.label,
    this.kind = SalePillKind.neutral,
    this.icon,
  });

  static Widget? forSale(BuildContext context, SaleHistoryItem sale) {
    final tr = context.tr;
    if (sale.isOfflinePending) {
      if (sale.status == SaleHistoryStatus.failed) {
        return SaleStatusPill(
          label: tr.shPillSyncFailed,
          kind: SalePillKind.bad,
          icon: PhosphorIconsRegular.warning,
        );
      }
      return SaleStatusPill(
        label: tr.shPillNotSynced,
        icon: PhosphorIconsRegular.clock,
      );
    }
    return switch (sale.status) {
      SaleHistoryStatus.failed => SaleStatusPill(
        label: tr.shPillSyncFailed,
        kind: SalePillKind.bad,
        icon: PhosphorIconsRegular.warning,
      ),
      SaleHistoryStatus.pending => SaleStatusPill(
        label: tr.shPillNotSynced,
        icon: PhosphorIconsRegular.clock,
      ),
      SaleHistoryStatus.refunded => SaleStatusPill(
        label: tr.shPillReturned,
        kind: SalePillKind.bad,
      ),
      SaleHistoryStatus.partialRefund => SaleStatusPill(
        label: tr.shPillPartial,
        kind: SalePillKind.bad,
      ),
      _ => null,
    };
  }

  factory SaleStatusPill.completed(BuildContext context) => SaleStatusPill(
    label: context.tr.shStatusCompleted,
    kind: SalePillKind.ok,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (bg, fg) = switch (kind) {
      SalePillKind.neutral => (colors.surfaceSoft, colors.textSecondary),
      SalePillKind.bad => (colors.dangerContainer, colors.danger),
      SalePillKind.ok => (colors.successContainer, colors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
