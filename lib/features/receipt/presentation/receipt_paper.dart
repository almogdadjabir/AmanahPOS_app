import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_format.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The paper: one white sheet of the roll's width, black ink in every theme.
/// A line-by-line port of the desktop `ReceiptVisual.Build`, so the phone and
/// the PC print the same receipt. Sizes are paper sizes in logical pixels
/// (1/96 inch), not UI design tokens. Do not restyle this with app tokens.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.doc,
    required this.settings,
    required this.l,
    required this.isRtl,
  });

  final ReceiptDoc doc;
  final ReceiptSettings settings;
  final AppLocalizations l;
  final bool isRtl;

  static const double _padX = 12;
  static const Color ink = Color(0xFF111111);
  static const Color grey = Color(0xFF555555);
  static const String poweredBy = 'Powered by AmanaPOS';
  static const String _font = 'Selawik';
  static const List<String> _fallback = ['IBMPlexSansArabic'];

  /// The sheet width for a roll: millimetres to 1/96 inch.
  static double widthFor(int paperMm) =>
      ReceiptSettings.normalizePaper(paperMm) * 96.0 / 25.4;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ..._header(),
      _rule(),
      ..._meta(),
      _rule(),
      ..._lines(),
      _rule(),
      ..._totals(),
      ..._payments(),
      ..._refunds(),
      _rule(),
      ..._footer(),
    ];
    // The paper never follows the phone's font size or zoom: it is a fixed
    // sheet, the same on every phone and on the PC.
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: _font,
            fontFamilyFallback: _fallback,
            fontSize: 12,
            color: ink,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
          ),
          child: Container(
            width: widthFor(settings.paperMm),
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(_padX, 16, _padX, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  // --- sections --------------------------------------------------------------

  List<Widget> _header() {
    final logo = settings.showLogo ? doc.logo : null;
    return [
      if (logo != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Center(
            child: Image.memory(
              logo,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 44),
            ),
          ),
        ),
      if (doc.businessName.isNotEmpty)
        _text(doc.businessName, 17, bold: true, center: true),
      if (doc.phone.isNotEmpty)
        _text(doc.phone, 11, center: true, grey: true, ltr: true),
    ];
  }

  List<Widget> _meta() => [
    _row(l.rcNumber, doc.number, valueLtr: true),
    _row(l.rcDate, receiptWhen(doc.at, doc.timezone), valueLtr: true),
    if ((doc.cashierName ?? '').trim().isNotEmpty)
      _row(l.rcCashier, doc.cashierName!, valueLtr: false),
    if ((doc.customerName ?? '').trim().isNotEmpty)
      _row(l.rcCustomer, doc.customerName!, valueLtr: false),
  ];

  List<Widget> _lines() {
    final out = <Widget>[];
    for (final line in doc.lines) {
      final hasDiscount = line.discount > 0;
      final hasReturned = line.returned > 0;
      out.add(
        _row(
          line.name,
          receiptAmount(line.total),
          valueLtr: true,
          wrapLabel: true,
        ),
      );
      out.add(
        _text(
          isolateLtr(
            '${receiptQty(line.quantity)} × ${receiptAmount(line.unitPrice)}',
          ),
          11,
          grey: true,
          bottom: hasReturned || hasDiscount ? 1 : 4,
        ),
      );
      if (hasDiscount) {
        out.add(
          _text(
            l.rcLineDiscount(receiptAmount(line.discount)),
            11,
            grey: true,
            bottom: hasReturned ? 1 : 4,
          ),
        );
      }
      if (hasReturned) {
        out.add(
          _text(
            l.rcReturnedQty(receiptQty(line.returned)),
            11,
            grey: true,
            bottom: 4,
          ),
        );
      }
    }
    return out;
  }

  List<Widget> _totals() {
    final breakdown = doc.discount > 0 || doc.tax > 0;
    final total = doc.currency.isNotEmpty
        ? '${doc.currency} ${receiptAmount(doc.net)}'
        : receiptAmount(doc.net);
    return [
      if (breakdown)
        _row(l.rcSubtotal, receiptAmount(doc.subtotal), valueLtr: true),
      if (doc.discount > 0)
        _row(l.rcDiscount, '− ${receiptAmount(doc.discount)}', valueLtr: true),
      if (doc.tax > 0)
        _row(receiptTaxLabel(doc, l), receiptAmount(doc.tax), valueLtr: true),
      _row(
        l.rcTotal,
        total,
        valueLtr: true,
        size: 15,
        bold: true,
        margin: const EdgeInsets.only(top: 4, bottom: 2),
      ),
    ];
  }

  List<Widget> _payments() {
    if (doc.payments.length > 1) {
      final hasCredit = doc.payments.any((p) => p.method == 'credit');
      return [
        for (final p in doc.payments)
          _row(
            // An on-account part is not paid yet: it is shown without "Paid".
            p.method == 'credit'
                ? receiptMethod(l, 'credit')
                : '${l.rcPaid} · ${receiptMethod(l, p.method)}',
            receiptAmount(p.amount),
            valueLtr: true,
          ),
        if (doc.customerOwes != null && hasCredit)
          _row(
            l.rcOwesNow,
            receiptAmount(doc.customerOwes!),
            valueLtr: true,
            bold: true,
          ),
      ];
    }
    if (doc.paymentMethod == 'credit') {
      return [
        _row(
          receiptMethod(l, 'credit'),
          receiptAmount(doc.net),
          valueLtr: true,
        ),
        if (doc.customerOwes != null)
          _row(
            l.rcOwesNow,
            receiptAmount(doc.customerOwes!),
            valueLtr: true,
            bold: true,
          ),
      ];
    }
    return [
      _row(
        '${l.rcPaid} · ${receiptMethod(l, doc.paymentMethod)}',
        receiptAmount(doc.net),
        valueLtr: true,
      ),
    ];
  }

  List<Widget> _refunds() => [
    for (final r in doc.refunds)
      _row(
        r.method.isEmpty
            ? l.rcRefund
            : '${l.rcRefund} · ${receiptMethod(l, r.method)}',
        '− ${receiptAmount(r.total)}',
        valueLtr: true,
      ),
  ];

  List<Widget> _footer() {
    final footer = settings.footer.isNotEmpty ? settings.footer : l.rcThanks;
    return [
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            receiptStatus(l, doc.status),
            style: _style(11, bold: true),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      if (!doc.isSynced)
        _text(l.rcNotSynced, 10.5, grey: true, center: true, bottom: 4, top: 1),
      _text(footer, 11, center: true, grey: true),
      _text(poweredBy, 10, center: true, grey: true, ltr: true, top: 2),
    ];
  }

  // --- building blocks -------------------------------------------------------

  Widget _rule() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedRule()),
    ),
  );

  Widget _row(
    String label,
    String value, {
    required bool valueLtr,
    bool wrapLabel = false,
    double size = 12,
    bool bold = false,
    EdgeInsets margin = const EdgeInsets.symmetric(vertical: 1),
  }) {
    return Padding(
      padding: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                label,
                style: _style(size, bold: bold),
                maxLines: wrapLabel ? null : 1,
                softWrap: wrapLabel,
                overflow: wrapLabel
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Directionality(
              textDirection: valueLtr || !isRtl
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: Text(value, style: _style(size, bold: bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(
    String text,
    double size, {
    bool bold = false,
    bool center = false,
    bool grey = false,
    bool ltr = false,
    double top = 1,
    double bottom = 1,
  }) {
    Widget t = Text(
      text,
      style: _style(size, bold: bold, grey: grey),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
    if (ltr) {
      t = Directionality(textDirection: TextDirection.ltr, child: t);
    }
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: center ? Center(child: t) : t,
    );
  }

  TextStyle _style(double size, {bool bold = false, bool grey = false}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: grey ? ReceiptPaper.grey : ink,
        decoration: TextDecoration.none,
      );
}

class _DashedRule extends CustomPainter {
  const _DashedRule();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReceiptPaper.grey
      ..strokeWidth = 1;
    const dash = 3.0;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += dash * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRule oldDelegate) => false;
}
