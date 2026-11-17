import 'dart:io';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

void main() {
  late Directory base;
  late Database db;
  late PendingUploadStore store;
  var clock = DateTime.utc(2026, 11, 17, 10);

  setUp(() async {
    base = await Directory.systemTemp.createTemp('pending_upload_test');
    db = await (await openTestDb()).database;
    clock = DateTime.utc(2026, 11, 17, 10);
    store = PendingUploadStore(
      baseDir: () async => base.path,
      now: () => clock,
    );
  });

  tearDown(() async {
    await db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  Future<File> source(List<int> bytes, [String name = 'pick.jpg']) async {
    final f = File(p.join(base.path, 'picker_tmp', name));
    await f.create(recursive: true);
    await f.writeAsBytes(bytes);
    return f;
  }

  Future<int> rows() async => Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM pending_uploads'),
  )!;

  test(
    'fresh v14 has pending_uploads and the v14 step is idempotent',
    () async {
      final cols = (await db.rawQuery(
        'PRAGMA table_info(pending_uploads)',
      )).map((r) => r['name']).toSet();
      expect(
        cols,
        containsAll([
          'scope',
          'entity',
          'entity_id',
          'local_path',
          'thumbnail_path',
          'sha256',
          'bytes',
          'state',
          'attempts',
          'next_attempt_at',
          'last_error',
        ]),
      );
      await OfflineDb.createV14Schema(db);
      await OfflineDb.createV14Schema(db);
      expect(await rows(), 0);
    },
  );

  test('prepare copies the bytes under pending_images/<entityId> and hashes '
      'them; the picked file is untouched', () async {
    final bytes = List<int>.generate(5000, (i) => i % 251);
    final src = await source(bytes);
    final staged = await store.prepare(
      entity: 'product',
      entityId: 'p1',
      source: src,
    );
    expect(staged.sha256, sha256.convert(bytes).toString());
    expect(staged.bytes, 5000);
    expect(
      p.isWithin(p.join(base.path, 'pending_images', 'p1'), staged.localPath),
      isTrue,
    );
    expect(await File(staged.localPath).readAsBytes(), bytes);
    expect(staged.thumbnailPath, staged.localPath);
    expect(src.existsSync(), isTrue);
    expect(await rows(), 0, reason: 'no row before stage');
  });

  test('stage writes a waiting row; a second stage replaces it and reports '
      'the old file as obsolete', () async {
    final a = await store.prepare(
      entity: 'product',
      entityId: 'p1',
      source: await source([1, 2, 3]),
    );
    final first = await db.transaction(
      (t) => store.stage(t, a, scope: 'u1|t1'),
    );
    expect(first.obsoleteFiles, isEmpty);
    expect(first.upload.state, PendingUpload.waiting);
    expect(first.upload.sha256, a.sha256);
    expect(first.upload.attempts, 0);

    final b = await store.prepare(
      entity: 'product',
      entityId: 'p1',
      source: await source([1, 2, 3], 'same.jpg'),
    );
    expect(b.localPath, isNot(a.localPath), reason: 'same bytes, new file');
    final second = await db.transaction(
      (t) => store.stage(t, b, scope: 'u1|t1'),
    );
    expect(second.obsoleteFiles, [a.localPath]);
    expect(await rows(), 1);
    final row = await store.get(db, 'product', 'p1');
    expect(row!.localPath, b.localPath);

    await store.deleteFiles(second.obsoleteFiles);
    expect(File(a.localPath).existsSync(), isFalse);
    expect(File(b.localPath).existsSync(), isTrue);
  });

  test('cancel removes the row and returns its files to delete', () async {
    final a = await store.prepare(
      entity: 'category',
      entityId: 'c1',
      source: await source([9, 9]),
    );
    await db.transaction((t) => store.stage(t, a, scope: 'u1|t1'));
    final files = await db.transaction(
      (t) => store.cancel(t, 'category', 'c1'),
    );
    expect(files, [a.localPath]);
    expect(await rows(), 0);
    await store.deleteFiles(files);
    expect(File(a.localPath).existsSync(), isFalse);
    expect(
      Directory(p.join(base.path, 'pending_images', 'c1')).existsSync(),
      isFalse,
      reason: 'empty entity folder removed',
    );
    // Cancelling nothing is a no-op.
    expect(
      await db.transaction((t) => store.cancel(t, 'category', 'c1')),
      isEmpty,
    );
  });

  test('discard deletes a staged file whose transaction failed', () async {
    final a = await store.prepare(
      entity: 'product',
      entityId: 'p9',
      source: await source([4, 5, 6]),
    );
    await store.discard(a);
    expect(File(a.localPath).existsSync(), isFalse);
  });

  test('due returns waiting rows whose next attempt is now or unset', () async {
    for (final id in ['a', 'b', 'c', 'd']) {
      final s = await store.prepare(
        entity: 'product',
        entityId: id,
        source: await source([id.codeUnitAt(0)], '$id.jpg'),
      );
      await db.transaction((t) => store.stage(t, s, scope: 'u1|t1'));
    }
    await db.update(
      'pending_uploads',
      {'next_attempt_at': '2026-11-17T11:00:00.000Z'},
      where: 'entity_id = ?',
      whereArgs: ['b'],
    );
    await db.update(
      'pending_uploads',
      {'next_attempt_at': '2026-11-17T09:00:00.000Z'},
      where: 'entity_id = ?',
      whereArgs: ['c'],
    );
    await db.update(
      'pending_uploads',
      {'state': PendingUpload.failed},
      where: 'entity_id = ?',
      whereArgs: ['d'],
    );
    final due = await store.due(db, scope: 'u1|t1');
    expect(due.map((u) => u.entityId), ['a', 'c']);
  });

  test('readers only return uploads of the given scope', () async {
    final a = await store.prepare(
      entity: 'product',
      entityId: 'pa',
      source: await source([1]),
    );
    await db.transaction((t) => store.stage(t, a, scope: 'uA|t1'));
    expect(await store.due(db, scope: 'uB|t2'), isEmpty);
    expect(await store.all(db, scope: 'uB|t2'), isEmpty);
    expect(await store.get(db, 'product', 'pa', scope: 'uB|t2'), isNull);
    expect((await store.due(db, scope: 'uA|t1')).single.entityId, 'pa');
    expect((await store.get(db, 'product', 'pa'))!.scope, 'uA|t1');
  });

  test('the row stores a path relative to pending_images; another base '
      'dir resolves it', () async {
    final a = await store.prepare(
      entity: 'product',
      entityId: 'p1',
      source: await source([1, 2]),
    );
    await db.transaction((t) => store.stage(t, a, scope: 'u1|t1'));
    final raw = (await db.query('pending_uploads')).single;
    expect(raw['local_path'], p.join('p1', p.basename(a.localPath)));
    expect(p.isRelative(raw['local_path'] as String), isTrue);

    final moved = await Directory.systemTemp.createTemp('pending_moved');
    addTearDown(() => moved.delete(recursive: true));
    final other = PendingUploadStore(baseDir: () async => moved.path);
    final up = (await other.get(db, 'product', 'p1'))!;
    expect(
      up.localPath,
      p.join(moved.path, 'pending_images', 'p1', p.basename(a.localPath)),
    );
    expect(await other.resolve(up.relativePath), up.localPath);
    expect(
      (await other.due(db, scope: 'u1|t1')).single.localPath,
      up.localPath,
    );
  });

  test('sweepOrphans deletes old unreferenced files and .part leftovers, '
      'keeps referenced and young files', () async {
    final kept = await store.prepare(
      entity: 'product',
      entityId: 'k',
      source: await source([1]),
    );
    await db.transaction((t) => store.stage(t, kept, scope: 'u1|t1'));
    final orphan = await store.prepare(
      entity: 'product',
      entityId: 'o',
      source: await source([2], 'o.jpg'),
    );
    final part = File(p.join(base.path, 'pending_images', 'k', 'x.part'));
    await part.writeAsBytes([3]);

    // Everything is younger than an hour: nothing goes.
    clock = DateTime.now();
    expect(await store.sweepOrphans(db), 0);
    expect(File(orphan.localPath).existsSync(), isTrue);

    clock = DateTime.now().add(const Duration(hours: 2));
    expect(await store.sweepOrphans(db), 2);
    expect(File(orphan.localPath).existsSync(), isFalse);
    expect(part.existsSync(), isFalse);
    expect(File(kept.localPath).existsSync(), isTrue);
    expect(
      Directory(p.join(base.path, 'pending_images', 'o')).existsSync(),
      isFalse,
    );
  });
}
