import 'dart:io';
import 'dart:typed_data';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

class SaleReceiptPdfService {
  SaleReceiptPdfService._();

  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;
  static pw.Font? _arabicRegular;
  static pw.Font? _arabicBold;

  static Future<void> _ensureFonts() async {
    if (_latinRegular != null &&
        _latinBold != null &&
        _arabicRegular != null &&
        _arabicBold != null) {
      return;
    }

    _latinRegular = await PdfGoogleFonts.notoSansRegular();
    _latinBold = await PdfGoogleFonts.notoSansBold();

    // Better Arabic rendering than normal NotoSans.
    _arabicRegular = await PdfGoogleFonts.notoNaskhArabicRegular();
    _arabicBold = await PdfGoogleFonts.notoNaskhArabicBold();
  }

  static const PdfColor _black = PdfColor.fromInt(0xFF0A0A0A);
  static const PdfColor _slate = PdfColor.fromInt(0xFF444444);
  static const PdfColor _muted = PdfColor.fromInt(0xFF888888);
  static const PdfColor _hairline = PdfColor.fromInt(0xFFE0E0E0);

  static const PdfColor _accentGreen = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _accentGreenMid = PdfColor.fromInt(0xFF0D9488);

  static const PdfColor _dangerText = PdfColor.fromInt(0xFFB42318);
  static const PdfColor _warningText = PdfColor.fromInt(0xFF92400E);

  static Future<Uint8List> buildBytes(
      SaleHistoryItem item, {
        required SaleReceiptPdfStrings strings,
      }) async {
    await _ensureFonts();

    final isRtl = strings.isRtl;
    final createdAt = DateFormat(
      'd MMM yyyy  •  HH:mm',
      strings.localeName,
    ).format(item.createdAt.toLocal());

    final receiptNo = item.receiptNumber?.trim().isNotEmpty == true
        ? item.receiptNumber!.trim()
        : item.displayRef;

    final doc = pw.Document(
      title: _safeText('${strings.receipt} ${item.displayRef}'),
      author: 'AmanaPOS',
      creator: 'AmanaPOS',
      producer: 'AmanaPOS',
      compress: true,
    );

    final theme = pw.ThemeData.withFont(
      base: strings.isArabic ? _arabicRegular! : _latinRegular!,
      bold: strings.isArabic ? _arabicBold! : _latinBold!,
      fontFallback: [
        _latinRegular!,
        _latinBold!,
        _arabicRegular!,
        _arabicBold!,
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(52, 48, 52, 64),
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        footer: (_) => _footer(strings),
        build: (_) => [
          _header(item, strings),
          pw.SizedBox(height: 32),
          _divider(),
          pw.SizedBox(height: 20),
          _receiptMeta(
            receiptNo: receiptNo,
            createdAt: createdAt,
            item: item,
            strings: strings,
          ),
          pw.SizedBox(height: 28),
          _divider(),
          pw.SizedBox(height: 20),
          _itemsTable(item, strings),
          pw.SizedBox(height: 20),
          _divider(),
          pw.SizedBox(height: 16),
          _totalRow(item, strings),
          if (item.isOfflinePending) ...[
            pw.SizedBox(height: 20),
            _offlineBanner(strings),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<File> createFile(
      SaleHistoryItem item, {
        required SaleReceiptPdfStrings strings,
      }) async {
    final bytes = await buildBytes(item, strings: strings);
    final dir = await getTemporaryDirectory();
    final name = 'amana_receipt_${_safeFileName(item.displayRef)}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<ShareResult> sharePdf(
      SaleHistoryItem item, {
        required SaleReceiptPdfStrings strings,
      }) async {
    final file = await createFile(item, strings: strings);

    return SharePlus.instance.share(
      ShareParams(
        title: strings.amanaReceipt,
        subject: _safeText('${strings.receipt} ${item.displayRef}'),
        text: _safeText(strings.receiptShareText(item.displayRef)),
        files: [
          XFile(
            file.path,
            name: file.uri.pathSegments.last,
            mimeType: 'application/pdf',
          ),
        ],
      ),
    );
  }

  static pw.Widget _header(
      SaleHistoryItem item,
      SaleReceiptPdfStrings strings,
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (!strings.isRtl) ...[
          _logo(),
          pw.SizedBox(width: 10),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: strings.isRtl
                ? pw.CrossAxisAlignment.end
                : pw.CrossAxisAlignment.start,
            children: [
              _t(
                'AmanaPOS',
                color: _black,
                size: 15,
                bold: true,
                strings: strings,
              ),
              pw.SizedBox(height: 1),
              _t(
                item.shopName?.trim().isNotEmpty == true
                    ? item.shopName!.trim()
                    : strings.salesReceipt,
                color: _muted,
                size: 8.5,
                strings: strings,
              ),
            ],
          ),
        ),
        if (strings.isRtl) ...[
          pw.SizedBox(width: 10),
          _logo(),
        ],
        pw.SizedBox(width: 12),
        _statusBadge(item.status, strings),
      ],
    );
  }

  static pw.Widget _logo() {
    return pw.Container(
      width: 36,
      height: 36,
      decoration: pw.BoxDecoration(
        color: _accentGreen,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          'A',
          style: pw.TextStyle(
            font: _latinBold,
            fontSize: 18,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _divider({double thickness = 0.5}) {
    return pw.Container(height: thickness, color: _hairline);
  }

  static pw.Widget _receiptMeta({
    required String receiptNo,
    required String createdAt,
    required SaleHistoryItem item,
    required SaleReceiptPdfStrings strings,
  }) {
    final metaItems = <pw.Widget>[
      _metaCol(label: strings.receiptUpper, value: receiptNo, strings: strings),
      _metaCol(label: strings.dateUpper, value: createdAt, strings: strings),
      _metaCol(
        label: strings.paymentUpper,
        value: strings.paymentLabel(item.paymentLabel),
        strings: strings,
      ),
      if (item.shopName?.trim().isNotEmpty == true)
        _metaCol(
          label: strings.shopUpper,
          value: item.shopName!.trim(),
          strings: strings,
        ),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: strings.isRtl ? metaItems.reversed.toList() : metaItems,
    );
  }

  static pw.Widget _metaCol({
    required String label,
    required String value,
    required SaleReceiptPdfStrings strings,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: strings.isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        children: [
          _t(
            label,
            color: _muted,
            size: 7,
            bold: true,
            spacing: strings.isRtl ? 0 : 1.0,
            strings: strings,
          ),
          pw.SizedBox(height: 4),
          _t(value, color: _black, size: 9.5, bold: true, strings: strings),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(
      SaleHistoryItem item,
      SaleReceiptPdfStrings strings,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              flex: 6,
              child: _t(
                strings.itemUpper,
                color: _muted,
                size: 7.5,
                bold: true,
                spacing: strings.isRtl ? 0 : 0.8,
                strings: strings,
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: _ltrText(
                strings.qtyUpper,
                color: _muted,
                size: 7.5,
                bold: true,
                align: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: _t(
                strings.amountUpper,
                color: _muted,
                size: 7.5,
                bold: true,
                spacing: strings.isRtl ? 0 : 0.8,
                align: pw.TextAlign.right,
                strings: strings,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        _divider(),
        if (item.items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            child: _t(
              strings.noItemDetailsAvailable,
              color: _muted,
              size: 9.5,
              strings: strings,
            ),
          )
        else
          ...item.items.map(
                (line) => pw.Column(
              children: [
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: _t(
                        line.productName,
                        color: _black,
                        size: 10,
                        bold: true,
                        maxLines: 2,
                        strings: strings,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: _ltrText(
                        line.quantity.toStringAsFixed(0),
                        color: _slate,
                        size: 10,
                        align: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: _ltrText(
                        AppFormat.moneyWithUnit(line.subtotal),
                        color: _black,
                        size: 10,
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                _divider(),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _totalRow(
      SaleHistoryItem item,
      SaleReceiptPdfStrings strings,
      ) {
    return pw.Column(
      children: [
        if (item.taxAmount > 0) ...[
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: strings.isRtl
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.start,
                  children: [
                    _t(
                      strings.taxUpper,
                      color: _muted,
                      size: 7.5,
                      bold: true,
                      spacing: strings.isRtl ? 0 : 1.0,
                      strings: strings,
                    ),
                  ],
                ),
              ),
              _ltrText(
                AppFormat.moneyWithUnit(item.taxAmount),
                color: _muted,
                size: 10,
                bold: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: strings.isRtl
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: [
                  _t(
                    strings.totalUpper,
                    color: _muted,
                    size: 7.5,
                    bold: true,
                    spacing: strings.isRtl ? 0 : 1.0,
                    strings: strings,
                  ),
                  pw.SizedBox(height: 3),
                  _t(
                    strings.paidVia(strings.paymentLabel(item.paymentLabel)),
                    color: _muted,
                    size: 8.5,
                    strings: strings,
                  ),
                ],
              ),
            ),
            _ltrText(
              AppFormat.moneyWithUnit(item.total),
              color: _accentGreen,
              size: 26,
              bold: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _statusBadge(
      SaleHistoryStatus status,
      SaleReceiptPdfStrings strings,
      ) {
    final label = strings.statusLabel(status);
    final color = _statusColor(status);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: _t(
        label,
        color: color,
        size: 8,
        bold: true,
        spacing: strings.isRtl ? 0 : 0.6,
        strings: strings,
      ),
    );
  }

  static pw.Widget _offlineBanner(SaleReceiptPdfStrings strings) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFF59E0B),
          width: 0.6,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: _t(
        strings.offlineSalePdfWarning,
        color: _warningText,
        size: 8.5,
        strings: strings,
      ),
    );
  }

  static pw.Widget _footer(SaleReceiptPdfStrings strings) {
    return pw.Column(
      children: [
        pw.Container(height: 0.5, color: _hairline),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _t(strings.thankYouForPurchase, color: _muted, size: 8, strings: strings),
            pw.Spacer(),
            _t(strings.poweredByAmanaPOS, color: _muted, size: 8, strings: strings),
          ],
        ),
      ],
    );
  }

  static pw.Text _t(
      Object? value, {
        required PdfColor color,
        required double size,
        required SaleReceiptPdfStrings strings,
        bool bold = false,
        double? spacing,
        pw.TextAlign? align,
        int? maxLines,
      }) {
    return pw.Text(
      _safeText(value),
      textAlign: align,
      maxLines: maxLines,
      textDirection: strings.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      style: pw.TextStyle(
        font: bold
            ? (strings.isArabic ? _arabicBold : _latinBold)
            : (strings.isArabic ? _arabicRegular : _latinRegular),
        fontBold: strings.isArabic ? _arabicBold : _latinBold,
        fontFallback: [
          _latinRegular!,
          _latinBold!,
          _arabicRegular!,
          _arabicBold!,
        ],
        color: color,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        letterSpacing: spacing,
      ),
    );
  }

  static pw.Text _ltrText(
      Object? value, {
        required PdfColor color,
        required double size,
        bool bold = false,
        pw.TextAlign? align,
        int? maxLines,
      }) {
    return pw.Text(
      _safeText(value),
      textAlign: align,
      textDirection: pw.TextDirection.ltr,
      maxLines: maxLines,
      style: pw.TextStyle(
        font: bold ? _latinBold : _latinRegular,
        fontBold: _latinBold,
        fontFallback: [
          _latinRegular!,
          _latinBold!,
          _arabicRegular!,
          _arabicBold!,
        ],
        color: color,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
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

class SaleReceiptPdfStrings {
  const SaleReceiptPdfStrings({
    required this.localeName,
    required this.isArabic,
    required this.isRtl,
    required this.receipt,
    required this.amanaReceipt,
    required this.salesReceipt,
    required this.receiptUpper,
    required this.dateUpper,
    required this.paymentUpper,
    required this.shopUpper,
    required this.itemUpper,
    required this.qtyUpper,
    required this.amountUpper,
    required this.totalUpper,
    required this.taxUpper,
    required this.noItemDetailsAvailable,
    required this.offlineSalePdfWarning,
    required this.thankYouForPurchase,
    required this.poweredByAmanaPOS,
    required this.cash,
    required this.card,
    required this.bankak,
    required this.bankTransfer,
    required this.wallet,
    required this.payment,
    required this.completed,
    required this.returned,
    required this.partiallyReturned,
    required this.cancelled,
    required this.failed,
    required this.pending,
    required this.unknown,
  });

  final String localeName;
  final bool isArabic;
  final bool isRtl;

  final String receipt;
  final String amanaReceipt;
  final String salesReceipt;

  final String receiptUpper;
  final String dateUpper;
  final String paymentUpper;
  final String shopUpper;
  final String itemUpper;
  final String qtyUpper;
  final String amountUpper;
  final String totalUpper;
  final String taxUpper;

  final String noItemDetailsAvailable;
  final String offlineSalePdfWarning;
  final String thankYouForPurchase;
  final String poweredByAmanaPOS;

  final String cash;
  final String card;
  final String bankak;
  final String bankTransfer;
  final String wallet;
  final String payment;

  final String completed;
  final String returned;
  final String partiallyReturned;
  final String cancelled;
  final String failed;
  final String pending;
  final String unknown;

  factory SaleReceiptPdfStrings.fromContext(BuildContext context) {
    final tr = context.tr;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.toLowerCase();

    return SaleReceiptPdfStrings(
      localeName: locale.toLanguageTag(),
      isArabic: languageCode == 'ar',
      isRtl: Directionality.of(context) == ui.TextDirection.rtl,
      receipt: tr.receipt,
      amanaReceipt: tr.amanaReceipt,
      salesReceipt: tr.salesReceipt,
      receiptUpper: languageCode == 'ar' ? tr.receipt : 'RECEIPT',
      dateUpper: languageCode == 'ar' ? tr.date : 'DATE',
      paymentUpper: languageCode == 'ar' ? tr.payment : 'PAYMENT',
      shopUpper: languageCode == 'ar' ? tr.shop : 'SHOP',
      itemUpper: languageCode == 'ar' ? tr.item : 'ITEM',
      qtyUpper: languageCode == 'ar' ? tr.qty : 'QTY',
      amountUpper: languageCode == 'ar' ? tr.amount : 'AMOUNT',
      totalUpper: languageCode == 'ar' ? tr.total : 'TOTAL',
      taxUpper: languageCode == 'ar' ? tr.taxLabel : 'TAX',
      noItemDetailsAvailable: tr.noItemDetailsAvailable,
      offlineSalePdfWarning: tr.offlineSalePdfWarning,
      thankYouForPurchase: tr.thankYouForPurchase,
      poweredByAmanaPOS: tr.poweredByAmanaPOS,
      cash: tr.cash,
      card: tr.card,
      bankak: tr.bankak,
      bankTransfer: tr.bankTransfer,
      wallet: tr.wallet,
      payment: tr.payment,
      completed: tr.completed,
      returned: tr.returned,
      partiallyReturned: tr.partiallyReturned,
      cancelled: tr.cancelled,
      failed: tr.failed,
      pending: tr.pending,
      unknown: tr.unknown,
    );
  }

  String paidVia(String method) {
    if (isArabic) return 'مدفوع عبر $method';
    return 'Paid via $method';
  }

  String receiptShareText(String ref) {
    if (isArabic) return 'إيصال $ref من AmanaPOS';
    return 'Receipt $ref from AmanaPOS';
  }

  String paymentLabel(String label) {
    final normalized = label.toLowerCase().trim();

    if (normalized.contains('cash')) return cash;
    if (normalized.contains('card')) return card;
    if (normalized.contains('bankak')) return bankak;
    if (normalized.contains('transfer')) return bankTransfer;
    if (normalized.contains('wallet')) return wallet;

    return label.trim().isEmpty ? payment : label.trim();
  }

  String statusLabel(SaleHistoryStatus status) {
    if (!isArabic) {
      return switch (status) {
        SaleHistoryStatus.completed => 'PAID',
        SaleHistoryStatus.refunded => 'REFUNDED',
        SaleHistoryStatus.partialRefund => 'PARTIAL REFUND',
        SaleHistoryStatus.cancelled => 'CANCELLED',
        SaleHistoryStatus.failed => 'FAILED',
        SaleHistoryStatus.pending => 'PENDING',
        _ => 'RECEIPT',
      };
    }

    return switch (status) {
      SaleHistoryStatus.completed => completed,
      SaleHistoryStatus.refunded => returned,
      SaleHistoryStatus.partialRefund => partiallyReturned,
      SaleHistoryStatus.cancelled => cancelled,
      SaleHistoryStatus.failed => failed,
      SaleHistoryStatus.pending => pending,
      _ => receipt,
    };
  }
}