// Review M6: another account's queued / rejected catalog rows and staged
// uploads never mark the signed-in account's lists.
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

void main() {
  test('marks are read for one scope; null scope reads every scope', () async {
    final db = await (await openTestDb()).database;
    Future<void> row(String id, String scope, String status) =>
        db.insert('outbox', {
          'mutation_id': 'm-$id-$scope',
          'entity': 'product',
          'op': 'update',
          'entity_id': id,
          'occurred_at': '2026-11-17T00:00:00Z',
          'payload_json': '{}',
          'status': status,
          'created_at': '2026-11-17T00:00:00Z',
          'scope': scope,
        });
    await row('p-mine', 'u1|t1', 'pending');
    await row('p-theirs', 'u2|t1', 'pending');
    await row('p-theirs-failed', 'u2|t1', 'rejected');
    await db.insert('pending_uploads', {
      'scope': 'u2|t1',
      'entity': 'product',
      'entity_id': 'p-their-image',
      'local_path': 'x',
      'thumbnail_path': 'x',
      'sha256': 'ab',
      'bytes': 1,
      'state': 'failed',
      'attempts': 1,
      'created_at': '2026-11-17T00:00:00Z',
    });

    final mine = await CatalogSyncMarks.load(db, 'product', scope: 'u1|t1');
    expect(mine.pending, {'p-mine'});
    expect(mine.failed, isEmpty);

    final all = await CatalogSyncMarks.load(db, 'product');
    expect(all.pending, {'p-mine', 'p-theirs'});
    expect(all.failed, {'p-theirs-failed', 'p-their-image'});
    await db.close();
  });
}
