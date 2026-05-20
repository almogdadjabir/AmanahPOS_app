import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension SaleHistoryStatusX on SaleHistoryStatus {
  Color get color => switch (this) {
    SaleHistoryStatus.completed => AppColors.primary,
    SaleHistoryStatus.refunded => AppColors.danger,
    SaleHistoryStatus.partialRefund => AppColors.danger,
    SaleHistoryStatus.cancelled => AppColors.danger,
    SaleHistoryStatus.failed => AppColors.danger,
    SaleHistoryStatus.pending => AppColors.warning,
    SaleHistoryStatus.unknown => AppColors.slate500,
  };

  Color get bg => switch (this) {
    SaleHistoryStatus.completed => AppColors.primaryLight,
    SaleHistoryStatus.refunded => AppColors.dangerLight,
    SaleHistoryStatus.partialRefund => AppColors.dangerLight,
    SaleHistoryStatus.cancelled => AppColors.dangerLight,
    SaleHistoryStatus.failed => AppColors.dangerLight,
    SaleHistoryStatus.pending => AppColors.warningLight,
    SaleHistoryStatus.unknown => AppColors.slate100,
  };

  Color get fgDark => switch (this) {
    SaleHistoryStatus.completed => AppColors.primaryDark,
    SaleHistoryStatus.refunded => AppColors.danger,
    SaleHistoryStatus.partialRefund => AppColors.danger,
    SaleHistoryStatus.cancelled => AppColors.danger,
    SaleHistoryStatus.failed => AppColors.danger,
    SaleHistoryStatus.pending => AppColors.warning,
    SaleHistoryStatus.unknown => AppColors.slate500,
  };

  IconData get icon => switch (this) {
    SaleHistoryStatus.completed => Icons.check_circle_rounded,
    SaleHistoryStatus.refunded => Icons.keyboard_return_rounded,
    SaleHistoryStatus.partialRefund => Icons.keyboard_return_rounded,
    SaleHistoryStatus.cancelled => Icons.cancel_rounded,
    SaleHistoryStatus.failed => Icons.error_rounded,
    SaleHistoryStatus.pending => Icons.pending_rounded,
    SaleHistoryStatus.unknown => Icons.receipt_long_rounded,
  };
}

// ─── SaleHistoryItem ──────────────────────────────────────────────────────────

extension SaleHistoryItemX on SaleHistoryItem {
  // ── Status helpers (offline overrides status) ────────────────────────────

  Color    get displayStatusColor => isOfflinePending ? AppColors.warning         : status.color;
  Color    get displayStatusBg    => isOfflinePending ? AppColors.warningLight    : status.bg;
  Color    get displayStatusFg    => isOfflinePending ? AppColors.warning         : status.fgDark;
  IconData get displayStatusIcon  => isOfflinePending ? Icons.wifi_off_rounded    : status.icon;

  // ── Payment colour ───────────────────────────────────────────────────────

  Color get paymentColor {
    final m = paymentMethod.toLowerCase();
    if (m == 'cash')                                 return AppColors.cash;
    if (m == 'card')                                 return AppColors.card;
    if (m == 'bankak' || m.contains('transfer'))     return AppColors.primary;
    if (m == 'mobile_wallet')                        return AppColors.primary;
    return AppColors.slate400;
  }

  // ── Date helpers ─────────────────────────────────────────────────────────

  bool get isToday {
    final n = DateTime.now();
    return createdAt.year == n.year &&
        createdAt.month == n.month &&
        createdAt.day   == n.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return createdAt.year == y.year &&
        createdAt.month == y.month &&
        createdAt.day   == y.day;
  }

  /// Section header label used when grouping the list by date.
  String get dateGroupLabel {
    if (isToday)     return 'Today';
    if (isYesterday) return 'Yesterday';

    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
        .inDays;

    if (diff < 7) return DateFormat('EEEE').format(createdAt); // e.g. "Monday"
    return DateFormat('MMM d, yyyy').format(createdAt);        // e.g. "May 15, 2026"
  }

  /// Short timestamp shown inside a tile.
  String get timeLabel => DateFormat('HH:mm').format(createdAt);

  /// Compact date + time for the detail sheet chips.
  String get dateTimeLabel => DateFormat('d MMM · HH:mm').format(createdAt);
}

// ─── DateTime ─────────────────────────────────────────────────────────────────

extension DateTimeX on DateTime {
  bool get isToday {
    final n = DateTime.now();
    return year == n.year && month == n.month && day == n.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return year == y.year && month == y.month && day == y.day;
  }
}