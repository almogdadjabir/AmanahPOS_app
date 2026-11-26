import 'dart:typed_data';
import 'dart:ui' as ui;

/// Printable dots across the paper: 80 mm = 576, 58 mm = 384 (8 dots per mm).
int receiptDotsFor(int paperMm) => paperMm == 58 ? 384 : 576;

/// Turns the receipt picture into ESC/POS raster bytes (`GS v 0`), so the
/// printer prints exactly what the screen shows, Arabic included. Black is
/// any pixel darker than the threshold; strips of at most 255 rows keep
/// cheap printers happy.
Future<List<int>> encodeReceiptRaster(
  Uint8List png, {
  required int paperMm,
  int threshold = 200,
}) async {
  final dots = receiptDotsFor(paperMm);
  final codec = await ui.instantiateImageCodec(png, targetWidth: dots);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final width = image.width;
  final height = image.height;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  codec.dispose();
  if (data == null) throw StateError('Could not read the receipt picture.');

  final rowBytes = (width + 7) ~/ 8;
  final out = <int>[0x1B, 0x40]; // ESC @
  const strip = 255;
  for (var y0 = 0; y0 < height; y0 += strip) {
    final rows = (y0 + strip > height) ? height - y0 : strip;
    out.addAll([
      0x1D, 0x76, 0x30, 0x00, //
      rowBytes & 0xFF, (rowBytes >> 8) & 0xFF,
      rows & 0xFF, (rows >> 8) & 0xFF,
    ]);
    for (var y = y0; y < y0 + rows; y++) {
      for (var xb = 0; xb < rowBytes; xb++) {
        var b = 0;
        for (var bit = 0; bit < 8; bit++) {
          final x = xb * 8 + bit;
          if (x >= width) continue;
          final i = (y * width + x) * 4;
          final a = data.getUint8(i + 3);
          // Transparent counts as paper (white).
          final lum = a == 0
              ? 255
              : (data.getUint8(i) * 299 +
                        data.getUint8(i + 1) * 587 +
                        data.getUint8(i + 2) * 114) ~/
                    1000;
          if (lum < threshold) b |= 0x80 >> bit;
        }
        out.add(b);
      }
    }
  }
  out
    ..addAll([0x1B, 0x64, 0x03]) // feed 3
    ..addAll([0x1D, 0x56, 0x42, 0x00]); // partial cut
  return out;
}
