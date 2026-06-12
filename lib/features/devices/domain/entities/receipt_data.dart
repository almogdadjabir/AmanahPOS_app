import 'package:equatable/equatable.dart';

/// One sold item line on a printed receipt.
class ReceiptLine extends Equatable {
  final String name;
  final int quantity;
  final String amount;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  @override
  List<Object?> get props => [name, quantity, amount];
}

/// A label/value summary row (subtotal, tax, total...).
class ReceiptRow extends Equatable {
  final String label;
  final String value;
  final bool emphasized;

  const ReceiptRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  List<Object?> get props => [label, value, emphasized];
}

/// Everything needed to render a receipt on a thermal printer.
/// All amounts arrive pre-formatted so the encoder stays presentation-free.
class ReceiptData extends Equatable {
  final String businessName;
  final String reference;
  final String dateLabel;
  final List<ReceiptLine> lines;
  final List<ReceiptRow> summary;
  final String paymentLabel;
  final String? offlineNote;
  final String footer;

  const ReceiptData({
    required this.businessName,
    required this.reference,
    required this.dateLabel,
    required this.lines,
    required this.summary,
    required this.paymentLabel,
    this.offlineNote,
    this.footer = 'Powered by AmanaPOS',
  });

  @override
  List<Object?> get props => [
        businessName,
        reference,
        dateLabel,
        lines,
        summary,
        paymentLabel,
        offlineNote,
        footer,
      ];
}
