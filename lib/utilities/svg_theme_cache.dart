import 'package:flutter/services.dart';

class SvgThemeCache {
  SvgThemeCache._();
  static final instance = SvgThemeCache._();

  final _rawCache = <String, String>{};
  final _processedCache = <String, String>{};

  String _toHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  String _key(String path, Map<String, Color> map) =>
      '$path::${map.entries.map((e) => '${e.key}=${e.value.value}').join('|')}';

  String _normalize(String svg) => svg
      .replaceAll('fill="black"',   'fill="#000000"')
      .replaceAll('fill="white"',   'fill="#FFFFFF"')
      .replaceAll('fill="red"',     'fill="#FF0000"')
      .replaceAll('fill="none"',    'fill="none"')
      .replaceAll('stroke="black"', 'stroke="#000000"')
      .replaceAll('stroke="white"', 'stroke="#FFFFFF"');

  Future<String> get(String path, Map<String, Color> colorMap) async {
    final key = _key(path, colorMap);
    if (_processedCache.containsKey(key)) return _processedCache[key]!;

    final raw = _rawCache[path] ??= await rootBundle.loadString(path);
    var svg = _normalize(raw); // ← normalize first, then replace
    for (final e in colorMap.entries) {
      svg = svg
          .replaceAll(e.key.toUpperCase(), _toHex(e.value))
          .replaceAll(e.key.toLowerCase(), _toHex(e.value));
    }
    return _processedCache[key] = svg;
  }

  void invalidate() => _processedCache.clear();
}