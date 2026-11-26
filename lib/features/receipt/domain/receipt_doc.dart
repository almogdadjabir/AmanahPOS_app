import 'dart:typed_data';

/// Everything one receipt shows, as plain data (no formatting, no language).
/// Mirrors the desktop `Receipt` record so both apps print the same paper.
class ReceiptDoc {
  final String businessName;
  final String phone;
  final Uint8List? logo;
  final String currency;
  final String number;
  final DateTime at;
  final String status;
  final List<ReceiptDocLine> lines;
  final double subtotal;
  final double discount;
  final double tax;
  final double net;
  final String paymentMethod;
  final List<ReceiptDocPayment> payments;
  final List<ReceiptDocRefund> refunds;
  final bool isSynced;
  final String? customerName;
  final double? customerOwes;
  final String? cashierName;
  final String? timezone;
  final String taxName;
  final double taxRate;
  final bool taxInclusive;

  const ReceiptDoc({
    required this.businessName,
    required this.phone,
    this.logo,
    required this.currency,
    required this.number,
    required this.at,
    required this.status,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.net,
    required this.paymentMethod,
    this.payments = const [],
    this.refunds = const [],
    required this.isSynced,
    this.customerName,
    this.customerOwes,
    this.cashierName,
    this.timezone,
    this.taxName = '',
    this.taxRate = 0,
    this.taxInclusive = false,
  });

  double get refunded => refunds.fold(0.0, (a, r) => a + r.total);
}

class ReceiptDocLine {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;
  final double returned;
  final double discount;

  const ReceiptDocLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.returned = 0,
    this.discount = 0,
  });
}

class ReceiptDocPayment {
  final String method;
  final double amount;

  const ReceiptDocPayment({required this.method, required this.amount});
}

class ReceiptDocRefund {
  final DateTime at;
  final String method;
  final double total;

  const ReceiptDocRefund({
    required this.at,
    required this.method,
    required this.total,
  });
}

/// Business details printed in the header.
class ReceiptBusiness {
  final String name;
  final String phone;
  final String currency;
  final Uint8List? logo;

  /// IANA zone of the business (the date prints in its time).
  final String? timezone;

  const ReceiptBusiness({
    this.name = '',
    this.phone = '',
    this.currency = '',
    this.logo,
    this.timezone,
  });
}

/// Receipt settings of the business (desktop `ReceiptSettings`).
class ReceiptSettings {
  static const int wide = 80;
  static const int narrow = 58;
  static const int footerMaxLength = 80;

  final int paperMm;
  final bool showLogo;
  final String footer;

  const ReceiptSettings({
    this.paperMm = wide,
    this.showLogo = true,
    this.footer = '',
  });

  static const ReceiptSettings defaults = ReceiptSettings();

  /// 58 stays 58; anything else is the 80 mm roll.
  static int normalizePaper(int mm) => mm == narrow ? narrow : wide;
}
