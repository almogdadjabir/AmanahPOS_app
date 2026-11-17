// Phase 3 Task 7 (Global Constraint): no REST catalog writer survives. The
// legacy cache writers overwrote or erased unsynced local rows, and the REST
// add/edit/delete of products, categories and vendors bypassed the outbox.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Removed names and REST endpoints of the three catalog entities.
final _banned = <Pattern>[
  // Legacy cache writers and their removal helpers.
  'saveProductsToCache',
  'saveCategoriesToCache',
  'saveVendors',
  'deleteProductFromCache',
  'removeVendorFromCache',
  // REST endpoints of products / categories / vendors (list, get, add,
  // edit, delete): the feed is the only source, the outbox the only writer.
  'api/v1/products/',
  'api/v1/inventory/vendors/',
];

/// The image PUT of the sync transport is the one allowed catalog endpoint
/// (`HttpSyncTransport.putImage`, foreground ImageUploader).
bool _allowed(String line) => line.contains("/image/'");

List<String> _scan(String path, List<String> lines) => [
  for (var i = 0; i < lines.length; i++)
    for (final b in _banned)
      if (lines[i].contains(b) && !_allowed(lines[i]))
        '$path:${i + 1}: $b',
];

void main() {
  test('the scanner catches every banned name (self-check)', () {
    for (final line in [
      'await offlineLocalCache.saveProductsToCache(x);',
      'cache.saveCategoriesToCache([c]);',
      'offlineLocalCache.saveVendors(v);',
      'await cache.deleteProductFromCache(id);',
      'cache.removeVendorFromCache(id);',
      "requestHandler.handlePostRequest('api/v1/products/', f);",
      "'api/v1/products/categories/\$id/',",
      "'api/v1/inventory/vendors/\$id/',",
    ]) {
      expect(_scan('x.dart', [line]), isNotEmpty, reason: line);
    }
    expect(
      _scan('x.dart', ["'product' => 'api/v1/products/\$entityId/image/',"]),
      isEmpty,
    );
  });

  test('no REST catalog writer remains in lib/', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      hits.addAll(_scan(f.path, f.readAsLinesSync()));
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
