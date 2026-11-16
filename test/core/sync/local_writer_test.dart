import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

void main() {
  late OfflineDb odb;
  late OutboxStore outbox;
  late DbChangeNotifier notifier;
  late LocalWriter writer;
  final events = <Set<String>>[];

  setUp(() async {
    odb = await openTestDb();
    final db = await odb.database;
    await db.execute('CREATE TABLE scratch (id TEXT PRIMARY KEY)');
    outbox = OutboxStore(odb);
    notifier = DbChangeNotifier();
    writer = LocalWriter(odb, outbox, notifier, scopeProvider: () => 'u1|t1');
    events.clear();
    notifier.changes.listen(events.add);
  });

  tearDown(() async {
    notifier.dispose();
    await (await odb.database).close();
  });

  Future<int> count(String t) async {
    final db = await odb.database;
    return (await db.rawQuery('SELECT COUNT(*) c FROM $t')).first['c'] as int;
  }

  Future<void> body(WriteScope s, String id) async {
    await s.txn.insert('scratch', {'id': id});
    await s.enqueue(
      entity: 'scratch',
      op: 'create',
      entityId: id,
      payload: {'id': id},
    );
  }

  test('row and outbox entry both visible after write', () async {
    await writer.write(tables: {'scratch'}, body: (s) => body(s, 'a'));
    expect(await count('scratch'), 1);
    expect(await count('outbox'), 1);
  });

  test('throwing body rolls back and does not notify', () async {
    await expectLater(
      writer.write(
        tables: {'scratch'},
        body: (s) async {
          await body(s, 'a');
          throw StateError('boom');
        },
      ),
      throwsStateError,
    );
    expect(await count('scratch'), 0);
    expect(await count('outbox'), 0);
    expect(events, isEmpty);
  });

  test('notifies once, after commit, for tables plus outbox', () async {
    final seen = <int>[];
    notifier.changes.listen((_) async => seen.add(await count('scratch')));
    await writer.write(tables: {'scratch'}, body: (s) => body(s, 'a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events, [
      {'scratch', 'outbox'},
    ]);
    expect(seen, [1]);
  });

  test('empty tables fires only the outbox event', () async {
    await writer.write(tables: {}, body: (s) => body(s, 'a'));
    expect(events, [
      {'outbox'},
    ]);
  });

  test('throwing listener does not fail write after commit', () async {
    final uncaught = <Object>[];
    final r = await runZonedGuarded(() async {
      notifier.changes.listen((_) => throw StateError('listener boom'));
      return writer.write(
        tables: {'scratch'},
        body: (s) async {
          await body(s, 'a');
          return 42;
        },
      );
    }, (e, st) => uncaught.add(e));
    expect(r, 42);
    expect(await count('scratch'), 1);
    expect(await count('outbox'), 1);
  });

  test('nested write throws StateError quickly and rolls back', () async {
    await expectLater(
      writer
          .write(
            tables: {'scratch'},
            body: (s) async {
              await body(s, 'a');
              await writer.write(
                tables: {'scratch'},
                body: (s2) => body(s2, 'b'),
              );
            },
          )
          .timeout(const Duration(seconds: 5)),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('must not be nested'),
        ),
      ),
    );
    expect(await count('scratch'), 0);
    expect(await count('outbox'), 0);
    expect(events, isEmpty);
  });

  test('concurrent writes serialise and get distinct seq', () async {
    final log = <String>[];
    Future<int> one(String id) => writer.write(
      tables: {'scratch'},
      body: (s) async {
        log.add('start $id');
        await s.txn.insert('scratch', {'id': id});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final e = await s.enqueue(
          entity: 'scratch',
          op: 'create',
          entityId: id,
          payload: {},
        );
        log.add('end $id');
        return e.seq!;
      },
    );
    final r = await Future.wait([one('a'), one('b')]);
    expect(r[0], isNot(r[1]));
    expect(await count('scratch'), 2);
    expect(log[0].substring(0, 5), 'start');
    expect(log[1], 'end ${log[0].substring(6)}');
    expect(log[2].substring(0, 5), 'start');
    expect(log[3], 'end ${log[2].substring(6)}');
  });
}
