import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amana_pos/features/receipt/services/receipt_raster_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(int w, int h, ui.Color c) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = c,
  );
  final img = await rec.endRecording().toImage(w, h);
  final d = await img.toByteData(format: ui.ImageByteFormat.png);
  return d!.buffer.asUint8List();
}

void main() {
  testWidgets('58 mm black picture becomes 48-byte raster rows', (t) async {
    await t.runAsync(() async {
      final png = await _png(16, 8, const ui.Color(0xFF000000));
      final bytes = await encodeReceiptRaster(
        png,
        paperMm: 58,
      );
      expect(bytes.take(2), [0x1B, 0x40]);
      expect(bytes.sublist(2, 6), [0x1D, 0x76, 0x30, 0x00]);
      expect(bytes[6], 48); // 384 dots / 8
      expect(bytes[7], 0);
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
      final rows = bytes[8] | (bytes[9] << 8);
      final data = bytes.sublist(10, 10 + 48 * rows);
      expect(data.every((b) => b == 0xFF), isTrue);
    });
  });

  testWidgets('white picture prints no ink', (t) async {
    await t.runAsync(() async {
      final png = await _png(16, 8, const ui.Color(0xFFFFFFFF));
      final bytes = await encodeReceiptRaster(png, paperMm: 80);
      expect(bytes[6], 72); // 576 / 8
      final rows = bytes[8] | (bytes[9] << 8);
      final data = bytes.sublist(10, 10 + 72 * rows);
      expect(data.every((b) => b == 0), isTrue);
    });
  });
}
