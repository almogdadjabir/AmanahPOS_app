import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';

/// Builds raw ESC/POS byte streams for thermal receipt printers.
///
/// Pure Dart — no plugin or platform dependency — so it is fully unit
/// testable. Defaults target an 80mm/3" printer (SAM4s Compact 3") which
/// fits 48 columns in Font A; pass [charsPerLine] = 32 for 58mm printers.
class EscPosEncoder {
  static const int defaultCharsPerLine = 48;

  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  final int charsPerLine;

  const EscPosEncoder({this.charsPerLine = defaultCharsPerLine});

  List<int> encodeReceipt(ReceiptData data) {
    final bytes = <int>[
      ..._initialize(),
      ..._alignCenter(),
      ..._doubleSize(),
      ..._text(data.businessName),
      ..._normalSize(),
      ..._feed(1),
      ..._text(data.reference),
      ..._text(data.dateLabel),
    ];

    if (data.offlineNote != null) {
      bytes.addAll([
        ..._bold(true),
        ..._text(data.offlineNote!),
        ..._bold(false),
      ]);
    }

    bytes.addAll([
      ..._alignLeft(),
      ..._text(_divider()),
    ]);

    for (final line in data.lines) {
      bytes.addAll(_text(_itemLine(line)));
    }

    bytes.addAll(_text(_divider()));

    for (final row in data.summary) {
      if (row.emphasized) {
        bytes.addAll([
          ..._bold(true),
          ..._text(_twoColumns(row.label, row.value)),
          ..._bold(false),
        ]);
      } else {
        bytes.addAll(_text(_twoColumns(row.label, row.value)));
      }
    }

    bytes.addAll([
      ..._text(_twoColumns('Payment', data.paymentLabel)),
      ..._text(_divider()),
      ..._alignCenter(),
      ..._text(data.footer),
      ..._feed(3),
      ..._cut(),
    ]);

    return bytes;
  }

  /// A short self-identification ticket used by the "Test print" action.
  List<int> encodeTestTicket({
    required String businessName,
    required String printerName,
    required String dateLabel,
  }) {
    return [
      ..._initialize(),
      ..._alignCenter(),
      ..._doubleSize(),
      ..._text(businessName),
      ..._normalSize(),
      ..._feed(1),
      ..._text('Printer test'),
      ..._text(printerName),
      ..._text(dateLabel),
      ..._feed(1),
      ..._text('If you can read this, your'),
      ..._text('printer is ready to use.'),
      ..._feed(3),
      ..._cut(),
    ];
  }

  // ── ESC/POS primitives ──────────────────────────────────────────────────

  List<int> _initialize() => [_esc, 0x40];

  List<int> _alignLeft() => [_esc, 0x61, 0x00];

  List<int> _alignCenter() => [_esc, 0x61, 0x01];

  List<int> _bold(bool on) => [_esc, 0x45, on ? 0x01 : 0x00];

  List<int> _doubleSize() => [_gs, 0x21, 0x11];

  List<int> _normalSize() => [_gs, 0x21, 0x00];

  List<int> _feed(int lines) => [_esc, 0x64, lines];

  /// Partial cut with feed (GS V 66) — supported by SAM4s and most
  /// ESC/POS printers; printers without a cutter ignore it.
  List<int> _cut() => [_gs, 0x56, 0x42, 0x00];

  /// Encodes a text line. Thermal printers speak single-byte codepages,
  /// so anything outside printable ASCII is replaced with '?'.
  List<int> _text(String value) {
    final sanitized = value.codeUnits
        .map((unit) => unit >= 0x20 && unit <= 0x7E ? unit : 0x3F)
        .toList();
    return [...sanitized, 0x0A];
  }

  String _divider() => '-' * charsPerLine;

  String _itemLine(ReceiptLine line) {
    final qty = 'x${line.quantity}';
    final right = '$qty  ${line.amount}';
    final maxNameWidth = charsPerLine - right.length - 1;
    final name = line.name.length > maxNameWidth
        ? line.name.substring(0, maxNameWidth)
        : line.name;
    return '$name${' ' * (charsPerLine - name.length - right.length)}$right';
  }

  String _twoColumns(String label, String value) {
    final space = charsPerLine - label.length - value.length;
    if (space < 1) return '$label $value';
    return '$label${' ' * space}$value';
  }
}
