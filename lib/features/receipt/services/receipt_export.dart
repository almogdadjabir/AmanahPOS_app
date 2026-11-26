import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Pixel ratio of the shared image: sharp on every chat app and in print.
const double kReceiptPixelRatio = 3.0;

/// A receipt picture and its size in logical pixels (the paper's size).
class RenderedReceipt {
  final Uint8List png;
  final double width;
  final double height;

  const RenderedReceipt(this.png, this.width, this.height);
}

/// Draws [paper] off screen (nobody sees it) and returns it as a PNG on
/// white. The receipt never has to be shown to be shared or printed.
///
/// The paper is put in the root overlay, far to the left, as tall as its
/// content, and captured through its [RepaintBoundary]. Works in release
/// builds (no debug-only calls).
Future<RenderedReceipt> renderReceiptWidgetPng(
  BuildContext context,
  Widget paper, {
  required double width,
  double pixelRatio = kReceiptPixelRatio,
}) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -(width + 2000),
      top: 0,
      width: width,
      // No height given: the paper is as tall as its content.
      child: RepaintBoundary(key: key, child: paper),
    ),
  );
  overlay.insert(entry);
  try {
    // Let the overlay lay out and paint the new entry.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext?.findRenderObject() as RenderBox?;
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('The receipt could not be drawn.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final size = boundary.size;
    image.dispose();
    if (data == null) throw StateError('Could not render the receipt.');
    return RenderedReceipt(data.buffer.asUint8List(), size.width, size.height);
  } finally {
    entry.remove();
  }
}

/// One PDF page as wide as the roll (`widthPx` is in 1/96 inch, the paper's
/// size) and as tall as the receipt, with the receipt picture filling it. The
/// PDF is the picture, so it looks exactly like the screen and the desktop.
Future<Uint8List> buildReceiptPdf(
  Uint8List png, {
  required double widthPx,
  required double heightPx,
}) async {
  final doc = pw.Document(
    title: 'Receipt',
    author: 'AmanaPOS',
    creator: 'AmanaPOS',
    producer: 'AmanaPOS',
  );
  final format = PdfPageFormat(
    widthPx * 72 / 96,
    heightPx * 72 / 96,
    marginAll: 0,
  );
  final image = pw.MemoryImage(png);
  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
    ),
  );
  return doc.save();
}

/// Keeps letters, digits, `-` and `_` so the name is a safe file name.
String receiptFileName(String number, String extension) {
  final cleaned = number
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  final base = cleaned.isEmpty
      ? DateTime.now().millisecondsSinceEpoch.toString()
      : cleaned;
  return 'receipt_$base.$extension';
}

Future<void> shareReceiptImage(
  Uint8List png, {
  required String number,
  Rect? origin,
}) => _shareFile(png, receiptFileName(number, 'png'), 'image/png', origin);

Future<void> shareReceiptPdf(
  Uint8List pdf, {
  required String number,
  Rect? origin,
}) =>
    _shareFile(pdf, receiptFileName(number, 'pdf'), 'application/pdf', origin);

/// Shares the file ONLY: no text is attached, so a chat app gets just the
/// receipt.
Future<void> _shareFile(
  Uint8List bytes,
  String name,
  String mime,
  Rect? origin,
) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, name: name, mimeType: mime)],
      sharePositionOrigin: origin,
    ),
  );
}
