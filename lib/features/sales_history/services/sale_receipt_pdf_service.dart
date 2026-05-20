import 'dart:io';
import 'dart:typed_data';

import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class SaleReceiptPdfService {
  SaleReceiptPdfService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _ensureFonts() async {
    if (_regular != null && _bold != null) return;
    _regular = await PdfGoogleFonts.notoSansRegular();
    _bold = await PdfGoogleFonts.notoSansBold();
  }

  static const PdfColor _black = PdfColor.fromInt(0xFF0A0A0A);
  static const PdfColor _slate = PdfColor.fromInt(0xFF444444);
  static const PdfColor _muted = PdfColor.fromInt(0xFF888888);
  static const PdfColor _hairline = PdfColor.fromInt(0xFFE0E0E0);

  static const PdfColor _accentGreen = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _accentGreenMid = PdfColor.fromInt(0xFF0D9488);

  static const PdfColor _dangerText = PdfColor.fromInt(0xFFB42318);
  static const PdfColor _warningText = PdfColor.fromInt(0xFF92400E);


  static Future<Uint8List> buildBytes(SaleHistoryItem item) async {
    await _ensureFonts();

    final createdAt = DateFormat('d MMM yyyy  •  HH:mm').format(item.createdAt);
    final receiptNo = item.receiptNumber?.trim().isNotEmpty == true
        ? item.receiptNumber!.trim()
        : item.displayRef;

    final doc = pw.Document(
      title: _safeText('Receipt ${item.displayRef}'),
      author: 'AmanaPOS',
      creator: 'AmanaPOS',
      producer: 'AmanaPOS',
      compress: true,
    );

    final theme = pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(52, 48, 52, 64),
        theme: theme,
        footer: (_) => _footer(),
        build: (_) => [
          _header(item),
          pw.SizedBox(height: 32),
          _divider(),
          pw.SizedBox(height: 20),
          _receiptMeta(receiptNo: receiptNo, createdAt: createdAt, item: item),
          pw.SizedBox(height: 28),
          _divider(),
          pw.SizedBox(height: 20),
          _itemsTable(item),
          pw.SizedBox(height: 20),
          _divider(),
          pw.SizedBox(height: 16),
          _totalRow(item),
          if (item.isOfflinePending) ...[
            pw.SizedBox(height: 20),
            _offlineBanner(),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<File> createFile(SaleHistoryItem item) async {
    final bytes = await buildBytes(item);
    final dir = await getTemporaryDirectory();
    final name = 'amana_receipt_${_safeFileName(item.displayRef)}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<ShareResult> sharePdf(SaleHistoryItem item) async {
    final file = await createFile(item);
    return SharePlus.instance.share(
      ShareParams(
        title: 'AmanaPOS Receipt',
        subject: _safeText('Receipt ${item.displayRef}'),
        text: _safeText('Receipt ${item.displayRef} from AmanaPOS'),
        files: [
          XFile(
            file.path,
            name:     file.uri.pathSegments.last,
            mimeType: 'application/pdf',
          ),
        ],
      ),
    );
  }


  static pw.Widget _header(SaleHistoryItem item) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width:  36,
          height: 36,
          decoration: pw.BoxDecoration(
            color: _accentGreen,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: _t('A',
                color: PdfColors.white, size: 18, bold: true),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _t('AmanaPOS', color: _black, size: 15, bold: true),
            pw.SizedBox(height: 1),
            _t(
              item.shopName?.trim().isNotEmpty == true
                  ? item.shopName!.trim()
                  : 'Sales Receipt',
              color: _muted, size: 8.5,
            ),
          ],
        ),
        pw.Spacer(),
        _statusBadge(item.status),
      ],
    );
  }

  static pw.Widget _divider({double thickness = 0.5}) {
    return pw.Container(height: thickness, color: _hairline);
  }

  static pw.Widget _receiptMeta({
    required String receiptNo,
    required String createdAt,
    required SaleHistoryItem item,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _metaCol(label: 'RECEIPT', value: receiptNo),
        _metaCol(label: 'DATE', value: createdAt),
        _metaCol(label: 'PAYMENT', value: item.paymentLabel),
        if (item.shopName?.trim().isNotEmpty == true)
          _metaCol(label: 'SHOP', value: item.shopName!.trim()),
      ],
    );
  }

  static pw.Widget _metaCol({
    required String label,
    required String value,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _t(label, color: _muted, size: 7, bold: true, spacing: 1.0),
          pw.SizedBox(height: 4),
          _t(value, color: _black, size: 9.5, bold: true),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(SaleHistoryItem item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              flex: 6,
              child: _t('ITEM', color: _muted, size: 7.5, bold: true, spacing: 0.8),
            ),
            pw.Expanded(
              flex: 1,
              child: _t('QTY', color: _muted, size: 7.5, bold: true,
                  spacing: 0.8, align: pw.TextAlign.right),
            ),
            pw.Expanded(
              flex: 2,
              child: _t('AMOUNT', color: _muted, size: 7.5, bold: true,
                  spacing: 0.8, align: pw.TextAlign.right),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        _divider(),
        if (item.items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            child: _t('No item details available', color: _muted, size: 9.5),
          )
        else
          ...item.items.map((line) => pw.Column(
            children: [
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: _t(line.productName,
                        color: _black, size: 10, bold: true, maxLines: 2),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: _t(line.quantity.toStringAsFixed(0),
                        color: _slate, size: 10,
                        align: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: _t(AppFormat.moneyWithUnit(line.subtotal),
                        color: _black, size: 10, bold: true,
                        align: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              _divider(),
            ],
          )),
      ],
    );
  }

  static pw.Widget _totalRow(SaleHistoryItem item) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('TOTAL', color: _muted, size: 7.5, bold: true, spacing: 1.0),
              pw.SizedBox(height: 3),
              _t('Paid via ${item.paymentLabel}', color: _muted, size: 8.5),
            ],
          ),
        ),
        _t(AppFormat.moneyWithUnit(item.total),
            color: _accentGreen, size: 26, bold: true),
      ],
    );
  }

  static pw.Widget _statusBadge(SaleHistoryStatus status) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: _t(label, color: color, size: 8, bold: true, spacing: 0.6),
    );
  }

  static pw.Widget _offlineBanner() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B), width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: _t(
        'Offline sale — final server confirmation may still be pending.',
        color: _warningText, size: 8.5,
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Container(height: 0.5, color: _hairline),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _t('Thank you for your purchase.',
                color: _muted, size: 8),
            pw.Spacer(),
            _t('Powered by AmanaPOS', color: _muted, size: 8),
          ],
        ),
      ],
    );
  }


  static pw.Text _t(
      Object? value, {
        required PdfColor color,
        required double size,
        bool bold = false,
        double? spacing,
        pw.TextAlign? align,
        int? maxLines,
      }) {
    return pw.Text(
      _safeText(value),
      textAlign: align,
      maxLines:  maxLines,
      style: pw.TextStyle(
        font: bold ? _bold : _regular,
        fontBold: _bold,
        color: color,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        letterSpacing: spacing,
      ),
    );
  }


  static PdfColor _statusColor(SaleHistoryStatus status) => switch (status) {
    SaleHistoryStatus.completed => _accentGreenMid,
    SaleHistoryStatus.refunded => _dangerText,
    SaleHistoryStatus.partialRefund => _dangerText,
    SaleHistoryStatus.cancelled => _dangerText,
    SaleHistoryStatus.failed => _dangerText,
    SaleHistoryStatus.pending => _warningText,
    _ => _muted,
  };

  static String _statusLabel(SaleHistoryStatus status) => switch (status) {
    SaleHistoryStatus.completed => 'PAID',
    SaleHistoryStatus.refunded => 'REFUNDED',
    SaleHistoryStatus.partialRefund => 'PARTIAL REFUND',
    SaleHistoryStatus.cancelled => 'CANCELLED',
    SaleHistoryStatus.failed => 'FAILED',
    SaleHistoryStatus.pending => 'PENDING',
    _ => 'RECEIPT',
  };


  static String _safeText(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll('\u00A0', ' ')
        .replaceAll('×', 'x')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2026', '...')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _safeFileName(String value) {
    final cleaned = _safeText(value)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : cleaned;
  }
}